"""Fast FIX message builder using unsafe memory operations.

High-performance message builder optimized for HFT applications.
Uses pre-allocated buffers and unsafe pointer operations for maximum speed.
"""

from collections import List
from memory import UnsafePointer, memcpy
from mojofix.time_utils import format_utc_timestamp

comptime SOH = ord(chr(1))
comptime EQUALS = ord("=")
comptime ZERO = ord("0")
comptime TWO_DIGITS_LOOKUP = "00010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657585960616263646566676869707172737475767778798081828384858687888990919293949596979899"


struct FastBuilder(Movable):
    """Fast FIX message builder using pre-allocated buffer.

    Key optimizations:
    - Pre-allocated buffer to avoid reallocations
    - Direct byte-level writes using UnsafePointer
    - Efficient integer-to-bytes conversion
    - Zero-copy field appending where possible
    - Buffer reuse via reset()

    Expected performance: 3-5x faster than safe FixMessage builder.
    """

    var buffer: List[UInt8]
    var position: Int
    var start_pos: Int  # Start of body data (after headroom)
    var begin_string: String
    var msg_type: String

    # Reserve space for header (8=...|9=...)
    # 128 bytes is plenty for header + msg type
    comptime HEADROOM = 128

    fn __init__(out self, capacity: Int = 4096):
        """Initialize builder with pre-allocated buffer.

        Args:
            capacity: Initial buffer capacity in bytes (default 4KB).
        """
        self.buffer = List[UInt8](capacity=capacity + Self.HEADROOM)
        # Pre-fill with zeros
        for _ in range(capacity + Self.HEADROOM):
            self.buffer.append(0)

        self.start_pos = Self.HEADROOM
        self.position = Self.HEADROOM
        self.begin_string = "FIX.4.2"
        self.msg_type = ""

    fn reset(mut self):
        """Reset builder for reuse (zero-allocation).

        Clears position but keeps allocated buffer.
        """
        self.position = Self.HEADROOM
        self.msg_type = ""

    fn _ensure_capacity(mut self, needed: Int):
        """Ensure buffer has enough capacity.

        Args:
            needed: Number of bytes needed.
        """
        var required = self.position + needed
        if required > len(self.buffer):
            # Double the buffer size
            var new_size = len(self.buffer) * 2
            while new_size < required:
                new_size *= 2

            # Resize buffer
            var old_len = len(self.buffer)
            for _ in range(new_size - old_len):
                self.buffer.append(0)

    fn _write_byte(mut self, byte: UInt8):
        """Write single byte to buffer.

        Args:
            byte: Byte to write.
        """
        self._ensure_capacity(1)
        self.buffer.unsafe_ptr()[self.position] = byte
        self.position += 1

    fn _write_bytes(mut self, data: String):
        """Write string bytes to buffer using memcpy for speed.

        Args:
            data: String to write.
        """
        var data_len = len(data)
        self._ensure_capacity(data_len)
        var data_bytes = data.as_bytes()

        # Use memcpy for bulk copy (vectorized internally)
        var src_ptr = data_bytes.unsafe_ptr()
        var dst_ptr = self.buffer.unsafe_ptr().offset(self.position)
        memcpy(dest=dst_ptr, src=src_ptr, count=data_len)

        self.position += data_len

    fn _write_int(mut self, value: Int):
        """Write integer as ASCII bytes to buffer.

        Args:
            value: Integer to write.
        """
        if value == 0:
            self._write_byte(ZERO)
            return

        var num = value
        var negative = False
        if num < 0:
            negative = True
            num = -num

        # Count digits
        var temp = num
        var digit_count = 0
        while temp > 0:
            digit_count += 1
            temp //= 10

        var total_len = digit_count
        if negative:
            total_len += 1

        self._ensure_capacity(total_len)

        # Write negative sign
        if negative:
            self.buffer.unsafe_ptr()[self.position] = ord("-")
            self.position += 1

        # Write digits in reverse
        var pos = self.position + digit_count - 1
        temp = num
        var ptr = self.buffer.unsafe_ptr()

        while temp > 0:
            ptr[pos] = ZERO + UInt8(temp % 10)
            temp //= 10
            pos -= 1

        self.position += digit_count

    fn _write_int_fast(mut self, value: Int):
        """Write integer using lookup table (faster)."""
        if value < 0:
            self._write_byte(ord("-"))
            self._write_int_fast(-value)
            return

        if value < 10:
            self._write_byte(ZERO + UInt8(value))
            return

        # Count digits
        var temp = value
        var digits = 0
        while temp > 0:
            digits += 1
            temp //= 10

        self._ensure_capacity(digits)
        var pos = self.position + digits
        self.position += digits

        # Write using lookup
        var v = value
        var ptr = self.buffer.unsafe_ptr()
        var lookup_ptr = TWO_DIGITS_LOOKUP.unsafe_ptr()

        while v >= 10:
            var rem = v % 100
            v //= 100
            var idx = rem * 2

            # Use unsafe pointers for maximum speed
            ptr[pos - 1] = lookup_ptr[idx + 1]
            ptr[pos - 2] = lookup_ptr[idx]
            pos -= 2

        if v > 0:
            ptr[pos - 1] = ZERO + UInt8(v)

    fn append_pair(mut self, tag: Int, value: String):
        """Append tag=value pair to message.

        Simplefix-compatible API.

        Args:
            tag: FIX field tag number.
            value: Field value.
        """
        # Special handling for BeginString and MsgType
        if tag == 8:
            self.begin_string = value
            return
        elif tag == 35:
            self.msg_type = value
            return

        # Write: tag=value\x01
        self._write_int(tag)
        self._write_byte(EQUALS)
        self._write_bytes(value)
        self._write_byte(SOH)

    fn append_pair(mut self, tag: Int, value: Int):
        """Append tag=value pair with integer value.

        Simplefix-compatible overload.

        Args:
            tag: FIX field tag number.
            value: Integer value.
        """
        if tag == 8 or tag == 35:
            self.append_pair(tag, String(value))
            return

        self._write_int_fast(tag)
        self._write_byte(EQUALS)
        self._write_int_fast(value)
        self._write_byte(SOH)

    fn append_pair(mut self, tag: Int, value: Float64):
        """Append tag=value pair with float value.

        Simplefix-compatible overload.

        Args:
            tag: FIX field tag number.
            value: Float value.
        """
        self.append_pair(tag, String(value))

    fn append_pair(mut self, tag: Int, value: Bool):
        """Append tag=value pair with boolean value (Y/N).

        Simplefix-compatible overload.

        Args:
            tag: FIX field tag number.
            value: Boolean value (True=Y, False=N).
        """
        self.append_pair(tag, "Y" if value else "N")

    fn append_comp_tag[TAG: Int](mut self, value: String):
        """Append field with compile-time known tag.

        This optimization pre-computes the tag bytes, eliminating
        runtime integer formatting and string allocation.

        Args:
            value: Field value.
        """

        # Special handling for BeginString and MsgType
        @parameter
        if TAG == 8:
            self.begin_string = value
            return

        @parameter
        if TAG == 35:
            self.msg_type = value
            return

        # Write tag bytes directly (compiled into constants)
        @parameter
        if TAG < 10:
            self._write_byte(ZERO + TAG)

        @parameter
        if TAG >= 10 and TAG < 100:
            self._write_byte(ZERO + (TAG // 10))
            self._write_byte(ZERO + (TAG % 10))

        @parameter
        if TAG >= 100:
            # Fallback for large tags (rare in performance critical paths)
            self._write_int(TAG)

        self._write_byte(EQUALS)
        self._write_bytes(value)
        self._write_byte(SOH)

    fn append_data(mut self, len_tag: Int, val_tag: Int, data: String):
        """Append raw data field with length prefix.

        Used for fields that may contain binary data including SOH.
        Examples: SecData (91/90), Signature (93/89), etc.

        Args:
            len_tag: Length field tag.
            val_tag: Data field tag.
            data: Raw data value.
        """
        self.append_pair(len_tag, len(data))
        self.append_pair(val_tag, data)

    fn append_utc_timestamp(
        mut self,
        tag: Int,
        timestamp: Float64,
        precision: Int = 3,
    ):
        """Append UTC timestamp field.

        Args:
            tag: FIX field tag number.
            timestamp: Unix timestamp.
            precision: Decimal places (0, 3, or 6).
        """
        var formatted = format_utc_timestamp(timestamp, precision)
        self.append_pair(tag, formatted)

    fn append_time(
        mut self,
        tag: Int,
        timestamp: Float64,
        precision: Int = 3,
    ):
        """Append UTC timestamp (simplefix-compatible alias).

        Args:
            tag: FIX field tag number.
            timestamp: Unix timestamp.
            precision: Decimal places (0, 3, or 6).
        """
        self.append_utc_timestamp(tag, timestamp, precision)

    fn _calculate_checksum(
        self, data: UnsafePointer[UInt8], length: Int
    ) -> Int:
        """Calculate FIX checksum.

        Args:
            data: Pointer to message bytes.
            length: Number of bytes.

        Returns:
            Checksum value (0-255).
        """
        var sum: Int = 0
        for i in range(length):
            sum += Int(data[i])
        return sum % 256

    fn encode(mut self) -> String:
        """Finalize and encode message with header and checksum.

        Uses zero-copy construction from internal buffer.
        """
        # 1. Calculate body length
        # Current position is end of body fields
        # Start of body fields is HEADROOM
        var body_len = self.position - self.start_pos

        # Add MsgType length: "35=" + value + SOH
        if self.msg_type != "":
            body_len += 4 + len(self.msg_type)

        # 2. Build header BACKWARDS from start_pos
        # We need to write: 8=FIX.4.2\x019=<len>\x01 (and optionally 35=...)
        # Actually, standard FIX header order is 8, 9, 35.
        # But we stored 35 separately.
        # Let's write the 35 part at the HEADROOM if we can, OR
        # better: write 8 and 9 into the headroom, but 35 needs to be AFTER 9.
        # And the body is already at HEADROOM.

        # Wait, if we just appended fields to buffer starting at HEADROOM,
        # then buffer[HEADROOM:] contains the body tags.
        # But 35 is a header tag, so it should be before body.
        # Ideally, we should have written 35 into the buffer first if it was regular.
        # But we treat it special.

        # OPTIMIZED PLAN:
        # We need [Header 8, 9, 35] + [Body] + [Trailer 10]
        # Body is at [HEADROOM : position]
        # We can write 8, 9, 35 into [HEADROOM-k : HEADROOM]
        # Then verify checksum on the whole range
        # Then append 10.

        var ptr = self.buffer.unsafe_ptr()
        var head_pos = self.start_pos

        # Write MsgType (35) first (backwards or forwards? backwards is hard for var len strings)
        # Actually, let's just write 35, 9, 8 backwards.

        # Write 35=...SOH
        if self.msg_type != "":
            head_pos -= 1
            ptr[head_pos] = SOH

            var mt_len = len(self.msg_type)
            var mt_ptr = self.msg_type.unsafe_ptr()
            head_pos -= mt_len
            memcpy(dest=ptr.offset(head_pos), src=mt_ptr, count=mt_len)

            head_pos -= 3
            memcpy(dest=ptr.offset(head_pos), src="35=".unsafe_ptr(), count=3)

        # Write 9=...SOH
        head_pos -= 1
        ptr[head_pos] = SOH

        var bl_temp = body_len
        if bl_temp == 0:
            head_pos -= 1
            ptr[head_pos] = ZERO
        else:
            while bl_temp > 0:
                head_pos -= 1
                ptr[head_pos] = ZERO + UInt8(bl_temp % 10)
                bl_temp //= 10

        head_pos -= 2
        memcpy(dest=ptr.offset(head_pos), src="9=".unsafe_ptr(), count=2)

        # Write 8=...SOH
        head_pos -= 1
        ptr[head_pos] = SOH

        var bs_len = len(self.begin_string)
        var bs_ptr = self.begin_string.unsafe_ptr()
        head_pos -= bs_len
        memcpy(dest=ptr.offset(head_pos), src=bs_ptr, count=bs_len)

        head_pos -= 2
        memcpy(dest=ptr.offset(head_pos), src="8=".unsafe_ptr(), count=2)

        # Now head_pos points to the start of the message
        # Message is from head_pos to position

        # 3. Calculate checksum
        var msg_len = self.position - head_pos
        from mojofix.simd_utils import calculate_checksum_ptr

        var checksum = calculate_checksum_ptr(ptr.offset(head_pos), msg_len)

        # 4. Append Checksum (10=...SOH)
        # We append this at the END (at self.position)
        var tail_len = 7  # 10=XXX\x01
        self._ensure_capacity(tail_len + 1)  # +1 for null terminator if needed

        ptr[self.position] = ord("1")
        ptr[self.position + 1] = ord("0")
        ptr[self.position + 2] = EQUALS

        var c_hundreds = checksum // 100
        var c_tens = (checksum % 100) // 10
        var c_ones = checksum % 10

        ptr[self.position + 3] = ZERO + UInt8(c_hundreds)
        ptr[self.position + 4] = ZERO + UInt8(c_tens)
        ptr[self.position + 5] = ZERO + UInt8(c_ones)
        ptr[self.position + 6] = SOH

        var total_len = msg_len + 7

        # Null terminate for string creation (not strictly needed for from_utf8_ptr but good safely)
        ptr[head_pos + total_len] = 0

        # 5. Create String view
        # We can create a string from the pointer.
        # CAVEAT: This creates a COPY of the data into the new String.
        # But it's only ONE copy (buffer -> new String), instead of TWO (buffer -> output -> new String).
        # And we assume the user takes ownership of the result.

        var result_ptr = ptr.offset(head_pos)
        return String(unsafe_from_utf8_ptr=result_ptr)

    fn build(mut self) -> String:
        """Build and return final message (alias for encode).

        Simplefix-compatible alias.

        Returns:
            Complete FIX message string.
        """
        return self.encode()
