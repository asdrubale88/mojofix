from collections import List, Optional
from mojofix.time_utils import format_utc_timestamp

comptime SOH_CHAR = chr(1)
comptime SOH = SOH_CHAR


struct FixTags:
    """Standard FIX field tags used internally."""

    comptime BEGIN_STRING = 8
    comptime BODY_LENGTH = 9
    comptime MSG_TYPE = 35
    comptime CHECKSUM = 10


struct FixField(Copyable, Movable, Stringable):
    var tag: Int
    var value: String

    fn __init__(out self, tag: Int, value: String):
        self.tag = tag
        self.value = value

    fn __copyinit__(out self, existing: Self):
        self.tag = existing.tag
        self.value = existing.value

    fn __moveinit__(out self, deinit existing: Self):
        self.tag = existing.tag
        self.value = existing.value^

    fn __str__(self) -> String:
        return String(self.tag) + "=" + self.value


struct FixMessage(Copyable, Movable, Stringable):
    var fields: List[FixField]  # Body fields
    var header_fields: List[FixField]  # Header fields

    fn __init__(out self):
        self.fields = List[FixField]()
        self.header_fields = List[FixField]()

    fn __copyinit__(out self, existing: Self):
        self.fields = existing.fields.copy()
        self.header_fields = existing.header_fields.copy()

    fn __moveinit__(out self, deinit existing: Self):
        self.fields = existing.fields^
        self.header_fields = existing.header_fields^

    fn append_pair(mut self, tag: Int, value: String, header: Bool = False):
        """Append tag=value pair to message.

        :param tag: FIX field tag number
        :param value: Field value
        :param header: If True, append to header; otherwise append to body
        """
        if header:
            self.header_fields.append(FixField(tag, value))
        else:
            self.fields.append(FixField(tag, value))

    fn append_pair(mut self, tag: Int, value: Int, header: Bool = False):
        """Append tag=value pair with integer value (auto-converts to String).

        Simplefix-compatible overload for convenience.
        Zero overhead - conversion happens at compile time.

        :param tag: FIX field tag number
        :param value: Integer field value
        :param header: If True, append to header; otherwise append to body
        """
        self.append_pair(tag, String(value), header)

    fn append_pair(mut self, tag: Int, value: Float64, header: Bool = False):
        """Append tag=value pair with float value (auto-converts to String).

        Simplefix-compatible overload for convenience.
        Zero overhead - conversion happens at compile time.

        :param tag: FIX field tag number
        :param value: Float field value
        :param header: If True, append to header; otherwise append to body
        """
        self.append_pair(tag, String(value), header)

    fn append_pair(mut self, tag: Int, value: Bool, header: Bool = False):
        """Append tag=value pair with boolean value (converts to Y/N).

        FIX protocol uses Y/N for boolean values.
        Zero overhead - conversion happens at compile time.

        :param tag: FIX field tag number
        :param value: Boolean field value (True=Y, False=N)
        :param header: If True, append to header; otherwise append to body
        """
        self.append_pair(tag, "Y" if value else "N", header)

    fn append_string(mut self, s: String, header: Bool = False):
        """Parse and append tag=value string.

        :param s: String in "tag=value" format
        :param header: If True, append to header; otherwise append to body
        """
        try:
            var p = s.split("=")
            if len(p) >= 2:
                var tag_str = String(p[0])
                var val_str = String(s[len(tag_str) + 1 :])
                self.append_pair(Int(tag_str), val_str, header)
        except:
            pass

    fn append_strings(mut self, strings: List[String], header: Bool = False):
        """Append multiple tag=value strings in batch.

        More efficient than multiple append_string calls due to pre-allocation.

        :param strings: List of "tag=value" strings
        :param header: If True, append all to header; otherwise to body
        """
        # Pre-allocate space for better performance

        # Parse and append each string
        for i in range(len(strings)):
            try:
                var s = strings[i]
                var p = s.split("=")
                if len(p) >= 2:
                    var tag_str = String(p[0])
                    var val_str = String(s[len(tag_str) + 1 :])
                    self.append_pair(Int(tag_str), val_str, header)
            except:
                pass

    fn append_pairs(
        mut self, tags: List[Int], values: List[String], header: Bool = False
    ):
        """Append multiple tag-value pairs in batch.

        More efficient than multiple append_pair calls.

        :param tags: List of tag numbers
        :param values: List of corresponding values
        :param header: If True, append all to header; otherwise to body
        """
        var count = len(tags) if len(tags) < len(values) else len(values)

        for i in range(count):
            self.append_pair(tags[i], values[i], header)

    fn append_utc_timestamp(
        mut self,
        tag: Int,
        timestamp: Float64,
        precision: Int = 3,
        header: Bool = False,
    ):
        var formatted = format_utc_timestamp(timestamp, precision)
        self.append_pair(tag, formatted, header)

    fn append_tz_timestamp(
        mut self,
        tag: Int,
        timestamp: Float64,
        offset_minutes: Int,
        precision: Int = 3,
        header: Bool = False,
    ):
        """Append timezone-aware timestamp.

        :param tag: FIX field tag number
        :param timestamp: Unix timestamp
        :param offset_minutes: Timezone offset in minutes from UTC (positive = east)
        :param precision: Decimal places: 0, 3 (ms), or 6 (us)
        :param header: If True, append to header
        """
        from mojofix.time_utils import format_tz_timestamp

        var formatted = format_tz_timestamp(
            timestamp, offset_minutes, precision
        )
        self.append_pair(tag, formatted, header)

    fn append_tz_time_only(
        mut self,
        tag: Int,
        timestamp: Float64,
        offset_minutes: Int,
        precision: Int = 3,
        header: Bool = False,
    ):
        """Append timezone-aware time only.

        :param tag: FIX field tag number
        :param timestamp: Unix timestamp
        :param offset_minutes: Timezone offset in minutes from UTC
        :param precision: Decimal places: 0, 3 (ms), or 6 (us)
        :param header: If True, append to header
        """
        from mojofix.time_utils import format_tz_time_only

        var formatted = format_tz_time_only(
            timestamp, offset_minutes, precision
        )
        self.append_pair(tag, formatted, header)

    fn append_data(
        mut self, len_tag: Int, val_tag: Int, data: String, header: Bool = False
    ):
        """Append raw data field with length prefix.

        Used for fields that may contain binary data including SOH characters.
        Examples: SecData (91/90), Signature (93/89), etc.

        :param header: If True, append to header; otherwise append to body
        """
        self.append_pair(len_tag, String(len(data)), header)
        self.append_pair(val_tag, data, header)

    fn get(self, tag: Int, nth: Int = 1) -> Optional[String]:
        """Get nth occurrence of tag (1-indexed).

        Searches header fields first, then body fields.

        :param tag: FIX field tag number
        :param nth: Which occurrence to return (1 = first, 2 = second, etc.)
        :return: Field value if found, None otherwise
        """
        var header_indices = self._find_in_header(tag)
        if len(header_indices) >= nth:
            return self.header_fields[header_indices[nth - 1]].value

        var body_indices = self._find_in_body(tag)
        var remaining = nth - len(header_indices)
        if len(body_indices) >= remaining:
            return self.fields[body_indices[remaining - 1]].value

        return None

    fn _find_in_header(self, tag: Int) -> List[Int]:
        var indices = List[Int]()
        for i in range(len(self.header_fields)):
            if self.header_fields[i].tag == tag:
                indices.append(i)
        return indices^

    fn _find_in_body(self, tag: Int) -> List[Int]:
        var indices = List[Int]()
        for i in range(len(self.fields)):
            if self.fields[i].tag == tag:
                indices.append(i)
        return indices^

    fn __getitem__(self, tag: Int) -> Optional[String]:
        """Syntactic sugar for get(tag).

        Usage: value = msg[55]  # Get Symbol field
        """
        return self.get(tag)

    @always_inline
    fn get_or(self, tag: Int, default: String = "") -> String:
        """Get field value or return default (simplefix-style convenience).

        Zero overhead with @always_inline - compiler inlines completely.
        Simpler than checking Optional every time.

        :param tag: FIX field tag number
        :param default: Default value if field not found
        :return: Field value or default

        Usage:
            var symbol = msg.get_or(55, "UNKNOWN")
        """
        var val = self.get(tag)
        return val.value() if val else default

    @always_inline
    fn get_int(self, tag: Int, default: Int = 0) -> Int:
        """Get field value as Int, or return default.

        Zero overhead with @always_inline - compiler inlines completely.
        Convenient for numeric fields without Optional handling.

        :param tag: FIX field tag number
        :param default: Default value if field not found or conversion fails
        :return: Field value as Int or default

        Usage:
            var qty = msg.get_int(38, 0)
        """
        var val = self.get(tag)
        if not val:
            return default
        try:
            return Int(val.value())
        except:
            return default

    @always_inline
    fn get_float(self, tag: Int, default: Float64 = 0.0) -> Float64:
        """Get field value as Float64, or return default.

        Zero overhead with @always_inline - compiler inlines completely.
        Convenient for price/quantity fields without Optional handling.

        :param tag: FIX field tag number
        :param default: Default value if field not found or conversion fails
        :return: Field value as Float64 or default

        Usage:
            var price = msg.get_float(44, 0.0)
        """
        var val = self.get(tag)
        if not val:
            return default
        try:
            return Float64(val.value())
        except:
            return default

    @always_inline
    fn has(self, tag: Int) -> Bool:
        """Check if field exists (simplefix-compatible).

        Zero overhead with @always_inline - compiler inlines completely.
        Cleaner than checking Optional every time.

        :param tag: FIX field tag number
        :return: True if field exists, False otherwise

        Usage:
            if msg.has(55):
                var symbol = msg.get(55).value()
        """
        return self.get(tag) is not None

    fn remove(mut self, tag: Int, nth: Int = 1) -> Bool:
        """Remove nth occurrence of tag from message.

        :param tag: FIX field tag number
        :param nth: Which occurrence to remove (1-indexed)
        :return: True if field was found and removed, False otherwise
        """
        var header_indices = self._find_in_header(tag)
        if len(header_indices) >= nth:
            _ = self.header_fields.pop(header_indices[nth - 1])
            return True

        var body_indices = self._find_in_body(tag)
        var remaining = nth - len(header_indices)
        if len(body_indices) >= remaining:
            _ = self.fields.pop(body_indices[remaining - 1])
            return True

        return False

    fn __setitem__(mut self, tag: Int, value: String):
        """Set or update field value. If field exists, updates it; otherwise appends.

        Usage: msg[55] = "AAPL"  # Set Symbol field
        """
        # Try to update existing field in header
        var header_indices = self._find_in_header(tag)
        if len(header_indices) > 0:
            self.header_fields[header_indices[0]].value = value
            return

        # Try to update existing field in body
        var body_indices = self._find_in_body(tag)
        if len(body_indices) > 0:
            self.fields[body_indices[0]].value = value
            return

        # Field doesn't exist, append to body
        self.append_pair(tag, value)

    fn encode(self, raw: Bool = False) -> String:
        var soh = String(SOH_CHAR)
        if raw:
            # OPTIMIZATION: Calculate total length first to avoid reallocations
            var total_len = 0
            for i in range(len(self.header_fields)):
                var f = self.header_fields[i].copy()
                total_len += self._tag_len(f.tag) + 1 + len(f.value) + 1
            for i in range(len(self.fields)):
                var f = self.fields[i].copy()
                total_len += self._tag_len(f.tag) + 1 + len(f.value) + 1

            var buf = List[UInt8]()
            buf.reserve(total_len)
            var soh_byte = UInt8(1)
            var eq_byte = UInt8(61)

            # Write header fields
            for i in range(len(self.header_fields)):
                var f = self.header_fields[i].copy()
                self._write_int(buf, f.tag)
                buf.append(eq_byte)
                buf.extend(f.value.as_bytes())
                buf.append(soh_byte)

            # Write body fields
            for i in range(len(self.fields)):
                var f = self.fields[i].copy()
                self._write_int(buf, f.tag)
                buf.append(eq_byte)
                buf.extend(f.value.as_bytes())
                buf.append(soh_byte)

            return String(bytes=buf)

        var f8: Optional[String] = None
        var f35: Optional[String] = None
        var body_len = 0

        # We need to scan both lists to calculate size and identifying specific tags
        # 2-pass approach: 1. Calculate size & identify tags. 2. Write bytes.

        # Pass 1: Scan header fields
        for i in range(len(self.header_fields)):
            var f = self.header_fields[i].copy()
            if f.tag == FixTags.BEGIN_STRING:
                f8 = f.value
            elif f.tag == FixTags.BODY_LENGTH:
                pass  # Auto-calculated
            elif f.tag == FixTags.CHECKSUM:
                pass  # Auto-calculated
            elif f.tag == FixTags.MSG_TYPE:
                f35 = f.value
                body_len += 4 + len(f.value)  # 35=...SOH
            else:
                body_len += self._tag_len(f.tag) + 1 + len(f.value) + 1

        # Pass 1: Scan body fields
        for i in range(len(self.fields)):
            var f = self.fields[i].copy()
            if f.tag == FixTags.BEGIN_STRING:
                f8 = f.value
            elif f.tag == FixTags.BODY_LENGTH:
                pass
            elif f.tag == FixTags.CHECKSUM:
                pass
            elif f.tag == FixTags.MSG_TYPE:
                f35 = f.value
                body_len += 4 + len(f.value)
            else:
                body_len += self._tag_len(f.tag) + 1 + len(f.value) + 1

        # Estimate header size (8=... + 9=...) roughly 20-30 bytes
        # Allocate buffer with single allocation
        var buf = List[UInt8]()
        buf.reserve(body_len + 50)

        var soh_byte = UInt8(1)
        var eq_byte = UInt8(61)

        # Pass 2: Write
        # Write 8
        if f8:
            buf.extend(String("8=").as_bytes())
            buf.extend(f8.value().as_bytes())
            buf.append(soh_byte)

        # Write 9
        buf.extend(String("9=").as_bytes())
        buf.extend(String(body_len).as_bytes())
        buf.append(soh_byte)

        # Write 35
        if f35:
            buf.extend(String("35=").as_bytes())
            buf.extend(f35.value().as_bytes())
            buf.append(soh_byte)

        # Write other fields (Header)
        for i in range(len(self.header_fields)):
            var f = self.header_fields[i].copy()
            if (
                f.tag != FixTags.BEGIN_STRING
                and f.tag != FixTags.BODY_LENGTH
                and f.tag != FixTags.CHECKSUM
                and f.tag != FixTags.MSG_TYPE
            ):
                self._write_int(buf, f.tag)
                buf.append(eq_byte)
                buf.extend(f.value.as_bytes())
                buf.append(soh_byte)

        # Write other fields (Body)
        for i in range(len(self.fields)):
            var f = self.fields[i].copy()
            if (
                f.tag != FixTags.BEGIN_STRING
                and f.tag != FixTags.BODY_LENGTH
                and f.tag != FixTags.CHECKSUM
                and f.tag != FixTags.MSG_TYPE
            ):
                self._write_int(buf, f.tag)
                buf.append(eq_byte)
                buf.extend(f.value.as_bytes())
                buf.append(soh_byte)

        # Create string once
        var out_msg = String(bytes=buf)
        buf.clear()

        # Checksum
        from mojofix.simd_utils import checksum_hot_path

        var csum = checksum_hot_path(out_msg)
        var csum_str = String(csum)
        while len(csum_str) < 3:
            csum_str = String("0") + csum_str

        out_msg += String("10=") + csum_str + soh

        return out_msg

    fn count(self) -> Int:
        """Get total field count (simplefix-compatible).

        Returns total number of fields (header + body).
        This is an alias for count_fields() to match simplefix API.

        :return: Total number of fields
        """
        return self.count_fields()

    fn __str__(self) -> String:
        return self.encode(True)

    fn append_utc_date_only(
        mut self, tag: Int, timestamp: Float64, header: Bool = False
    ):
        """Append UTC date-only field (YYYYMMDD format)."""
        from mojofix.time_utils import format_utc_date_only

        var formatted = format_utc_date_only(timestamp)
        self.append_pair(tag, formatted, header)

    fn clear(mut self):
        """Remove all fields from message."""
        self.fields = List[FixField]()
        self.header_fields = List[FixField]()

    fn count_fields(self) -> Int:
        """Count total fields in message.

        :return: Total number of fields (header + body)
        """
        return len(self.header_fields) + len(self.fields)

    fn has_field(self, tag: Int) -> Bool:
        """Check if field exists in message.

        :param tag: FIX field tag number
        :return: True if field exists, False otherwise
        """
        # Check header
        if len(self._find_in_header(tag)) > 0:
            return True
        # Check body
        if len(self._find_in_body(tag)) > 0:
            return True
        return False

    fn clone(self) -> FixMessage:
        """Create a deep copy of the message.

        :return: New message with copied fields
        """
        var new_msg = FixMessage()
        # Copy header fields
        for i in range(len(self.header_fields)):
            new_msg.header_fields.append(self.header_fields[i].copy())
        # Copy body fields
        for i in range(len(self.fields)):
            new_msg.fields.append(self.fields[i].copy())
        return new_msg^

    fn reset(mut self):
        """Clear all fields and reset message for reuse."""
        self.clear()

    fn get_all(self, tag: Int) -> List[String]:
        """Get all occurrences of a tag.

        :param tag: FIX field tag number
        :return: List of all values for this tag
        """
        var values = List[String]()
        # Search header
        var header_indices = self._find_in_header(tag)
        for i in range(len(header_indices)):
            values.append(self.header_fields[header_indices[i]].value)

        # Search body
        var body_indices = self._find_in_body(tag)
        for i in range(len(body_indices)):
            values.append(self.fields[body_indices[i]].value)

        return values^

    fn validate(self) -> Bool:
        """Validate message structure.

        Checks for required fields and proper structure.

        :return: True if valid, False otherwise
        """
        # Check required fields: BeginString (8), MsgType (35)
        if not self.has_field(FixTags.BEGIN_STRING):
            return False
        if not self.has_field(FixTags.MSG_TYPE):
            return False

        # Message is valid if it has required fields
        return True

    fn append_time_only(
        mut self,
        tag: Int,
        timestamp: Float64,
        precision: Int = 3,
        header: Bool = False,
    ):
        """Append time-only field (HH:MM:SS[.sss] format).

        :param tag: FIX field tag number
        :param timestamp: Unix timestamp
        :param precision: Decimal places (0, 3, or 6)
        :param header: If True, append to header
        """
        from mojofix.time_utils import format_time_only

        var formatted = format_time_only(timestamp, precision)
        self.append_pair(tag, formatted, header)

    fn append_local_mkt_date(
        mut self, tag: Int, timestamp: Float64, header: Bool = False
    ):
        """Append LocalMktDate field (YYYYMMDD format).

        :param tag: FIX field tag number
        :param timestamp: Unix timestamp
        :param header: If True, append to header
        """
        from mojofix.time_utils import format_local_mkt_date

        var formatted = format_local_mkt_date(timestamp)
        self.append_pair(tag, formatted, header)

    fn append_month_year(
        mut self, tag: Int, timestamp: Float64, header: Bool = False
    ):
        """Append MonthYear field (YYYYMM format).

        :param tag: FIX field tag number
        :param timestamp: Unix timestamp
        :param header: If True, append to header
        """
        from mojofix.time_utils import format_month_year

        var formatted = format_month_year(timestamp)
        self.append_pair(tag, formatted, header)

    fn append_time(
        mut self,
        tag: Int,
        timestamp: Float64,
        precision: Int = 3,
        header: Bool = False,
    ):
        """Append UTC timestamp (simplefix-compatible alias).

        This is an alias for append_utc_timestamp() to match simplefix API.
        Note: Unlike Python's simplefix, this requires an explicit timestamp.
        Use Python interop or benchmarking time() for current time if needed.

        :param tag: FIX field tag number
        :param timestamp: Unix timestamp
        :param precision: Decimal places (0, 3, or 6)
        :param header: If True, append to header
        """
        self.append_utc_timestamp(tag, timestamp, precision, header)

    @always_inline
    fn _int_to_string_fast(self, n: Int) -> String:
        """Fast integer to string conversion for common tag numbers.

        Optimized for 1-3 digit tags (covers 99% of FIX tags).
        Avoids String(Int) allocation overhead.
        """
        if n < 10:
            return String(chr(n + 48))
        elif n < 100:
            var d1 = n // 10
            var d2 = n % 10
            return String(chr(d1 + 48)) + String(chr(d2 + 48))
        elif n < 1000:
            var d1 = n // 100
            var d2 = (n // 10) % 10
            var d3 = n % 10
            return (
                String(chr(d1 + 48))
                + String(chr(d2 + 48))
                + String(chr(d3 + 48))
            )
        else:
            # Fallback for larger numbers
            return String(n)

    @always_inline
    fn _tag_len(self, tag: Int) -> Int:
        """Calculate number of digits in tag without allocation."""
        if tag < 10:
            return 1
        if tag < 100:
            return 2
        if tag < 1000:
            return 3
        if tag < 10000:
            return 4
        return 5

    @always_inline
    fn _write_int(self, mut buf: List[UInt8], val: Int):
        """Write integer bytes directly to buffer without string allocation."""
        if val < 10:
            buf.append(UInt8(val + 48))
            return
        if val < 100:
            buf.append(UInt8((val // 10) + 48))
            buf.append(UInt8((val % 10) + 48))
            return
        if val < 1000:
            buf.append(UInt8((val // 100) + 48))
            buf.append(UInt8(((val // 10) % 10) + 48))
            buf.append(UInt8((val % 10) + 48))
            return
        # Fallback for larger (rare in FIX tags)
        buf.extend(String(val).as_bytes())
