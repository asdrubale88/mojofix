"""Fast FIX message representation avoiding string allocations.

This module provides a fast message structure that minimizes allocations.
"""

from collections import List


struct FieldRef(Copyable):
    """A FIX field reference (tag + value indices)."""

    var tag: Int
    var value_start: Int
    var value_end: Int

    fn __init__(out self, tag: Int, value_start: Int, value_end: Int):
        self.tag = tag
        self.value_start = value_start
        self.value_end = value_end

    fn __copyinit__(out self, existing: Self):
        self.tag = existing.tag
        self.value_start = existing.value_start
        self.value_end = existing.value_end


struct FastMessage(Movable):
    """Fast FIX message using indices for zero-copy.

    Stores field values as indices into the original message string,
    avoiding string allocations during parsing.
    Expected performance: 3-5x faster than safe FixMessage.
    """

    var _data: String  # Owns the message data
    var fields: List[FieldRef]

    fn __init__(out self, data: String):
        """Create message with owned data."""
        self._data = data
        self.fields = List[FieldRef]()

    fn add_field(mut self, tag: Int, value_start: Int, value_end: Int):
        """Add field to message using indices.

        Args:
            tag: FIX tag number.
            value_start: Start index of value in _data.
            value_end: End index of value in _data.
        """
        self.fields.append(FieldRef(tag, value_start, value_end))

    fn get(self, tag: Int) -> String:
        """Get first occurrence of tag.

        Args:
            tag: FIX tag number.

        Returns:
            Field value, or empty string if not found.
        """
        for i in range(len(self.fields)):
            if self.fields[i].tag == tag:
                return String(
                    self._data[
                        self.fields[i].value_start : self.fields[i].value_end
                    ]
                )
        return String("")

    fn get_nth(self, tag: Int, nth: Int) -> String:
        """Get nth occurrence of tag (1-indexed).

        Args:
            tag: FIX tag number.
            nth: Which occurrence (1 = first).

        Returns:
            Field value, or empty string if not found.
        """
        var found = 0
        for i in range(len(self.fields)):
            if self.fields[i].tag == tag:
                found += 1
                if found == nth:
                    return String(
                        self._data[
                            self.fields[i]
                            .value_start : self.fields[i]
                            .value_end
                        ]
                    )
        return String("")

    fn has_field(self, tag: Int) -> Bool:
        """Check if tag exists in message.

        Args:
            tag: FIX tag number.

        Returns:
            True if tag exists.
        """
        for i in range(len(self.fields)):
            if self.fields[i].tag == tag:
                return True
        return False

    fn field_count(self) -> Int:
        """Get number of fields in message."""
        return len(self.fields)

    fn clear(mut self):
        """Clear all fields (for reuse)."""
        self.fields.clear()
