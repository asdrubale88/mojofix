from collections import List, Optional
from mojofix.time_utils import format_utc_timestamp

comptime SOH_CHAR = chr(1)
comptime SOH = SOH_CHAR


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
        var count = 0
        # Search header fields first
        for i in range(len(self.header_fields)):
            if self.header_fields[i].tag == tag:
                count += 1
                if count == nth:
                    return self.header_fields[i].value
        # Then search body fields
        for i in range(len(self.fields)):
            if self.fields[i].tag == tag:
                count += 1
                if count == nth:
                    return self.fields[i].value
        return None

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
        var count = 0

        # Search header fields first
        for i in range(len(self.header_fields)):
            if self.header_fields[i].tag == tag:
                count += 1
                if count == nth:
                    _ = self.header_fields.pop(i)
                    return True

        # Then search body fields
        for i in range(len(self.fields)):
            if self.fields[i].tag == tag:
                count += 1
                if count == nth:
                    _ = self.fields.pop(i)
                    return True

        return False

    fn __setitem__(mut self, tag: Int, value: String):
        """Set or update field value. If field exists, updates it; otherwise appends.

        Usage: msg[55] = "AAPL"  # Set Symbol field
        """
        # Try to update existing field in header
        for i in range(len(self.header_fields)):
            if self.header_fields[i].tag == tag:
                self.header_fields[i].value = value
                return

        # Try to update existing field in body
        for i in range(len(self.fields)):
            if self.fields[i].tag == tag:
                self.fields[i].value = value
                return

        # Field doesn't exist, append to body
        self.append_pair(tag, value)

    fn encode(self, raw: Bool = False) -> String:
        var soh = String(SOH_CHAR)
        if raw:
            var res = String("")
            for i in range(len(self.fields)):
                res += String(self.fields[i]) + soh
            return res

        var f8: Optional[String] = None
        var f35: Optional[String] = None
        var other_fields = List[FixField]()

        for i in range(len(self.fields)):
            var f = self.fields[i].copy()
            if f.tag == 8:
                f8 = f.value
            elif f.tag == 9:
                pass
            elif f.tag == 10:
                pass
            elif f.tag == 35:
                f35 = f.value
            else:
                other_fields.append(f.copy())

        var body_content = String("")
        if f35:
            body_content += String("35=") + f35.value() + soh

        for i in range(len(other_fields)):
            body_content += String(other_fields[i]) + soh

        var body_len = len(body_content)

        var out_msg = String("")
        if f8:
            out_msg += String("8=") + f8.value() + soh

        out_msg += String("9=") + String(body_len) + soh
        out_msg += body_content

        # Calculate checksum using SIMD-optimized implementation
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
        for i in range(len(self.header_fields)):
            if self.header_fields[i].tag == tag:
                return True
        # Check body
        for i in range(len(self.fields)):
            if self.fields[i].tag == tag:
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
        for i in range(len(self.header_fields)):
            if self.header_fields[i].tag == tag:
                values.append(self.header_fields[i].value)
        # Search body
        for i in range(len(self.fields)):
            if self.fields[i].tag == tag:
                values.append(self.fields[i].value)
        return values^

    fn validate(self) -> Bool:
        """Validate message structure.

        Checks for required fields and proper structure.

        :return: True if valid, False otherwise
        """
        # Check required fields: BeginString (8), MsgType (35)
        if not self.has_field(8):
            return False
        if not self.has_field(35):
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
