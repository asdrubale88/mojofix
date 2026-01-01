from collections import List, Optional
from mojofix.message import FixMessage, FixField, FixTags

comptime SOH = chr(1)


struct ParserConfig(Copyable, Movable):
    """Configuration options for FIX message parsing."""

    var allow_empty_values: Bool
    var allow_missing_begin_string: Bool
    var strip_fields_before_begin_string: Bool

    fn __init__(
        out self,
        allow_empty_values: Bool = False,
        allow_missing_begin_string: Bool = False,
        strip_fields_before_begin_string: Bool = True,
    ):
        """Create parser configuration."""
        self.allow_empty_values = allow_empty_values
        self.allow_missing_begin_string = allow_missing_begin_string
        self.strip_fields_before_begin_string = strip_fields_before_begin_string

    fn __copyinit__(out self, existing: Self):
        self.allow_empty_values = existing.allow_empty_values
        self.allow_missing_begin_string = existing.allow_missing_begin_string
        self.strip_fields_before_begin_string = (
            existing.strip_fields_before_begin_string
        )

    fn __moveinit__(out self, deinit existing: Self):
        self.allow_empty_values = existing.allow_empty_values
        self.allow_missing_begin_string = existing.allow_missing_begin_string
        self.strip_fields_before_begin_string = (
            existing.strip_fields_before_begin_string
        )


struct FixParser:
    var buffer: String
    var raw_len_tags: List[Int]
    var raw_data_tags: List[Int]
    var config: ParserConfig

    fn __init__(out self, config: ParserConfig = ParserConfig()):
        """Initialize parser with optional configuration."""
        self.buffer = String("")
        self.config = config.copy()
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

    fn append_buffer(mut self, data: String):
        self.buffer += data

    fn get_message(mut self) -> Optional[FixMessage]:
        if len(self.buffer) == 0:
            return None

        var start_pos = self.buffer.find(String(FixTags.BEGIN_STRING) + "=")
        if start_pos == -1:
            return None

        if start_pos > 0:
            self.buffer = String(self.buffer[start_pos:])
            _ = start_pos

        var pattern_9 = String(SOH) + String(FixTags.BODY_LENGTH) + "="
        var pos_9 = self.buffer.find(pattern_9)
        if pos_9 == -1:
            return None

        var val_start = pos_9 + len(pattern_9)
        var pos_next_soh = self.buffer.find(String(SOH), val_start)
        if pos_next_soh == -1:
            return None

        var body_len_str = String(self.buffer[val_start:pos_next_soh])
        try:
            var body_len = Int(body_len_str)
            var body_start = pos_next_soh + 1
            var total_end = body_start + body_len + 7

            if len(self.buffer) < total_end:
                return None

            var raw_msg = String(self.buffer[:total_end])
            self.buffer = String(self.buffer[total_end:])

            return self._parse_raw(raw_msg)

        except:
            self.buffer = String(self.buffer[1:])
            return None

    fn _parse_raw(self, raw: String) -> FixMessage:
        """Parse raw message string into FixMessage, handling raw data fields.

        Uses state machine to track length-prefixed raw data fields (e.g., SecData 91/90).
        When a length tag is encountered, the subsequent data tag's value is read as
        exactly N bytes instead of scanning for SOH.
        """
        var msg = FixMessage()
        var point = 0
        var raw_len = 0  # Saved length from most recent raw_len_tag

        while point < len(raw):
            # Find next tag (scan for '=')
            var tag_start = point
            var eq_pos = raw.find("=", point)
            if eq_pos == -1:
                # No more fields
                break

            # Extract tag number optimized
            var tag = self._parse_tag_fast(raw, tag_start, eq_pos)
            if tag == 0:
                # Invalid tag or parse error
                point += 1
                continue

            # Check if this is a raw data field
            var is_raw_data_tag = False
            for i in range(len(self.raw_data_tags)):
                if tag == self.raw_data_tags[i]:
                    is_raw_data_tag = True
                    break

            var value: String
            if is_raw_data_tag and raw_len > 0:
                # This is a raw data field: read exactly raw_len bytes
                var val_start = eq_pos + 1
                var val_end = val_start + raw_len

                if val_end > len(raw):
                    # Not enough data in buffer (shouldn't happen if get_message computed correctly)
                    break

                value = String(raw[val_start:val_end])
                point = val_end + 1  # Skip past value + SOH
                raw_len = 0  # Reset for next raw data field
            else:
                # Normal field: scan for SOH
                var val_start = eq_pos + 1
                var soh_pos = raw.find(String(SOH), val_start)

                if soh_pos == -1:
                    # No SOH found, take rest of string
                    value = String(raw[val_start:])
                    point = len(raw)
                else:
                    value = String(raw[val_start:soh_pos])
                    point = soh_pos + 1

            # Check for empty values
            if len(value) == 0 and not self.config.allow_empty_values:
                continue

            # Check if this is a raw length tag
            var is_raw_len_tag = False
            for i in range(len(self.raw_len_tags)):
                if tag == self.raw_len_tags[i]:
                    is_raw_len_tag = True
                    break

            if is_raw_len_tag:
                # Save the length for the next raw data field
                try:
                    raw_len = Int(value)
                except:
                    raw_len = 0

            # Append the field
            msg.append_pair(tag, value)

        return msg^

    @always_inline
    fn _parse_tag_fast(self, s: String, start_pos: Int, end_pos: Int) -> Int:
        """Parse integer tag from string slice without allocation.

        Optimized for positive integers. Returns 0 on error.
        """
        if start_pos >= end_pos:
            return 0

        # Access internal pointer for speed would be ideal, but using getitem is safe fallback
        # Given we are inside FixParser which holds 'buffer' as String, we are parsing 'raw' which is a slice.

        var res = 0
        var ptr = s.unsafe_ptr() + start_pos
        var len = end_pos - start_pos

        # Check first char
        var first = ptr.load(0)
        if first < 48 or first > 57:
            return 0

        for i in range(len):
            var c = ptr.load(i)
            if c < 48 or c > 57:
                return 0
            res = res * 10 + Int(c - 48)

        return res
