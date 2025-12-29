from collections import List, Optional
from mojofix.message import FixMessage, FixField

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

        var start_pos = self.buffer.find("8=")
        if start_pos == -1:
            return None

        if start_pos > 0:
            self.buffer = String(self.buffer[start_pos:])
            start_pos = 0

        var pattern_9 = String(SOH) + "9="
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
        var msg = FixMessage()
        var parts = raw.split(String(SOH))
        for i in range(len(parts)):
            var s = String(parts[i])
            if len(s) > 0:
                # Check config for empty values
                var eq_pos = s.find("=")
                if eq_pos != -1:
                    var val = String(s[eq_pos + 1 :])
                    if len(val) == 0 and not self.config.allow_empty_values:
                        continue
                msg.append_string(s)
        return msg^
