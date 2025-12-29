"""Zero-copy FIX parser for HFT.

⚠️ WARNING: This parser performs minimal validation for maximum speed.
- No automatic bounds checking
- Assumes well-formed FIX messages
- Arena must be managed by caller
"""

from memory import UnsafePointer
from mojofix.hft.arena import Arena
from mojofix.hft.string_view import StringView
from mojofix.hft.message_view import MessageView

comptime SOH = chr(1)


struct ArenaParser:
    """Zero-copy FIX parser using arena allocation.

    Key optimizations:
    - No string allocations during parsing
    - SIMD-optimized delimiter scanning (future)
    - Direct pointer arithmetic
    """

    var arena: Arena
    var raw_len_tags: List[Int]
    var raw_data_tags: List[Int]

    fn __init__(out self, arena_capacity: Int = 1024 * 1024):
        """Create parser with arena.

        Args:
            arena_capacity: Size of arena in bytes (default 1MB).
        """
        self.arena = Arena(arena_capacity)
        self.raw_len_tags = List[Int]()
        self.raw_data_tags = List[Int]()

        # SecData: 91/90
        self.raw_len_tags.append(91)
        self.raw_data_tags.append(90)
        # Signature: 93/89
        self.raw_len_tags.append(93)
        self.raw_data_tags.append(89)
        # XmlData: 212/213
        self.raw_len_tags.append(212)
        self.raw_data_tags.append(213)
        # EncodedText: 354/355
        self.raw_len_tags.append(354)
        self.raw_data_tags.append(355)

    fn parse_message(mut self, data: String) raises -> MessageView:
        """Parse FIX message into zero-copy view.

        ⚠️ UNSAFE: The returned MessageView references arena memory.
        Do not use after arena is reset or freed.

        Args:
            data: Raw FIX message string.

        Returns:
            MessageView with fields pointing into arena.
        """
        # Copy message data into arena
        var data_bytes = data.as_bytes()
        var msg_ptr = self.arena.write_bytes(
            UnsafePointer[UInt8].address_of(data_bytes[0]), len(data_bytes)
        )

        if not msg_ptr:
            raise Error("Arena full - cannot allocate message")

        # Parse into MessageView
        return self._parse_raw(msg_ptr, len(data_bytes))

    fn _parse_raw(
        self, data: UnsafePointer[UInt8], length: Int
    ) raises -> MessageView:
        """Parse raw bytes into MessageView.

        Args:
            data: Pointer to message data in arena.
            length: Length of message in bytes.

        Returns:
            MessageView with zero-copy field references.
        """
        var msg = MessageView()
        var pos = 0
        var raw_len = 0

        while pos < length:
            # Find '=' delimiter
            var eq_pos = self._find_byte(data, pos, length, ord("="))
            if eq_pos == -1:
                break

            # Parse tag
            var tag = self._parse_int(data, pos, eq_pos)
            if tag == -1:
                pos += 1
                continue

            # Check if this is a raw data tag
            var is_raw_data = False
            for i in range(len(self.raw_data_tags)):
                if tag == self.raw_data_tags[i]:
                    is_raw_data = True
                    break

            var value_start = eq_pos + 1
            var value_end: Int

            if is_raw_data and raw_len > 0:
                # Raw data field: read exactly raw_len bytes
                value_end = value_start + raw_len
                if value_end > length:
                    break
                pos = value_end + 1  # Skip SOH
                raw_len = 0
            else:
                # Normal field: find SOH
                var soh_pos = self._find_byte(
                    data, value_start, length, ord(SOH)
                )
                if soh_pos == -1:
                    value_end = length
                    pos = length
                else:
                    value_end = soh_pos
                    pos = soh_pos + 1

            # Create StringView for value (zero-copy!)
            var value_view = StringView(
                data + value_start, value_end - value_start
            )

            # Add field to message
            msg.add_field(tag, value_view)

            # Check if this is a raw length tag
            var is_raw_len = False
            for i in range(len(self.raw_len_tags)):
                if tag == self.raw_len_tags[i]:
                    is_raw_len = True
                    break

            if is_raw_len:
                try:
                    raw_len = value_view.to_int()
                except:
                    raw_len = 0

        return msg^

    fn _find_byte(
        self, data: UnsafePointer[UInt8], start: Int, end: Int, byte: Int
    ) -> Int:
        """Find first occurrence of byte in range.

        TODO: Replace with SIMD-optimized scan for 10x speedup.

        Args:
            data: Data buffer.
            start: Start position.
            end: End position.
            byte: Byte to find.

        Returns:
            Position of byte, or -1 if not found.
        """
        for i in range(start, end):
            if Int(data[i]) == byte:
                return i
        return -1

    fn _parse_int(
        self, data: UnsafePointer[UInt8], start: Int, end: Int
    ) -> Int:
        """Parse integer from byte range.

        Args:
            data: Data buffer.
            start: Start position.
            end: End position (exclusive).

        Returns:
            Parsed integer, or -1 on error.
        """
        var result = 0
        var negative = False
        var i = start

        if i < end and data[i] == ord("-"):
            negative = True
            i += 1

        if i >= end:
            return -1

        while i < end:
            var digit = Int(data[i]) - ord("0")
            if digit < 0 or digit > 9:
                return -1
            result = result * 10 + digit
            i += 1

        return -result if negative else result

    fn reset_arena(mut self):
        """Reset arena for reuse (invalidates all MessageViews)."""
        self.arena.reset()
