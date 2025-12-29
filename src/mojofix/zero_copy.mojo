"""Zero-copy parsing utilities for mojofix.

Provides zero-allocation field access by storing offsets into the original buffer
instead of creating intermediate String copies.
"""

from collections import List, Optional


struct ZeroCopyField(Copyable, Movable):
    """Field reference with offset into buffer instead of String copy."""

    var tag: Int
    var value_start: Int
    var value_len: Int

    fn __init__(out self, tag: Int, value_start: Int, value_len: Int):
        self.tag = tag
        self.value_start = value_start
        self.value_len = value_len

    fn __copyinit__(out self, existing: Self):
        self.tag = existing.tag
        self.value_start = existing.value_start
        self.value_len = existing.value_len

    fn __moveinit__(out self, deinit existing: Self):
        self.tag = existing.tag
        self.value_start = existing.value_start
        self.value_len = existing.value_len

    fn get_value(self, buffer: String) -> String:
        """Extract value from buffer (creates String only when needed)."""
        return String(
            buffer[self.value_start : self.value_start + self.value_len]
        )


struct ZeroCopyMessage(Copyable, Movable):
    """FIX message with zero-copy field access.

    Stores the original buffer and field offsets, avoiding intermediate allocations.
    Expected: 2-3x fewer allocations vs regular FixMessage.
    """

    var buffer: String
    var fields: List[ZeroCopyField]

    fn __init__(out self, buffer: String):
        self.buffer = buffer
        self.fields = List[ZeroCopyField]()

    fn __copyinit__(out self, existing: Self):
        self.buffer = existing.buffer
        self.fields = existing.fields.copy()

    fn __moveinit__(out self, deinit existing: Self):
        self.buffer = existing.buffer^
        self.fields = existing.fields^

    fn add_field(mut self, tag: Int, value_start: Int, value_len: Int):
        """Add field reference (no String allocation)."""
        self.fields.append(ZeroCopyField(tag, value_start, value_len))

    fn get(self, tag: Int) -> Optional[String]:
        """Get field value by tag (allocates String only when accessed)."""
        for i in range(len(self.fields)):
            if self.fields[i].tag == tag:
                return self.fields[i].get_value(self.buffer)
        return None

    fn count_fields(self) -> Int:
        """Count total fields."""
        return len(self.fields)


fn parse_zero_copy(buffer: String) -> ZeroCopyMessage:
    """Parse FIX message with zero-copy field access.

    Only stores field offsets, no intermediate String allocations.
    Expected: 2-3x fewer allocations, 30-50% faster than regular parser.

    :param buffer: Complete FIX message buffer
    :return: Zero-copy message with field references
    """
    var msg = ZeroCopyMessage(buffer)
    var soh = chr(1)

    var pos = 0
    while pos < len(buffer):
        # Find tag=value separator
        var eq_pos = buffer.find("=", pos)
        if eq_pos == -1:
            break

        # Find field terminator (SOH)
        var soh_pos = buffer.find(String(soh), eq_pos)
        if soh_pos == -1:
            soh_pos = len(buffer)

        # Parse tag
        try:
            var tag_str = String(buffer[pos:eq_pos])
            var tag = Int(tag_str)

            # Store field reference (no value String allocation)
            var value_start = eq_pos + 1
            var value_len = soh_pos - value_start
            msg.add_field(tag, value_start, value_len)
        except:
            pass

        pos = soh_pos + 1

    return msg^
