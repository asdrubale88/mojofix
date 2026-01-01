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

    Optimized Layout (Structure of Arrays):
    - Separate arrays for tags, starts, ends
    - Improves cache locality for tag searches
    - Reduces memory bandwidth usage
    """

    var _data: String  # Owns the message data
    var _tags: List[Int]
    var _starts: List[Int]
    var _ends: List[Int]

    fn __init__(out self, data: String):
        """Create message with owned data."""
        self._data = data
        self._tags = List[Int]()
        self._starts = List[Int]()
        self._ends = List[Int]()

    fn reserve(mut self, capacity: Int):
        """Reserve capacity for fields to avoid reallocations."""
        self._tags.reserve(capacity)
        self._starts.reserve(capacity)
        self._ends.reserve(capacity)

    @always_inline
    fn add_field(mut self, tag: Int, value_start: Int, value_end: Int):
        """Add field to message using indices.

        Args:
            tag: FIX tag number.
            value_start: Start index of value in _data.
            value_end: End index of value in _data.
        """
        self._tags.append(tag)
        self._starts.append(value_start)
        self._ends.append(value_end)

    fn get(self, tag: Int) -> String:
        """Get first occurrence of tag.

        Args:
            tag: FIX tag number.

        Returns:
            Field value, or empty string if not found.
        """
        # Optimized SoA search: only scan tags array
        for i in range(len(self._tags)):
            if self._tags[i] == tag:
                return String(self._data[self._starts[i] : self._ends[i]])
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
        for i in range(len(self._tags)):
            if self._tags[i] == tag:
                found += 1
                if found == nth:
                    return String(self._data[self._starts[i] : self._ends[i]])
        return String("")

    fn has_field(self, tag: Int) -> Bool:
        """Check if tag exists in message.

        Args:
            tag: FIX tag number.

        Returns:
            True if tag exists.
        """
        # Optimized SoA search
        for i in range(len(self._tags)):
            if self._tags[i] == tag:
                return True
        return False

    fn field_count(self) -> Int:
        """Get number of fields in message."""
        return len(self._tags)

    fn clear(mut self):
        """Clear all fields (for reuse)."""
        self._tags.clear()
        self._starts.clear()
        self._ends.clear()

    fn count(self) -> Int:
        """Get field count (simplefix-compatible alias).

        Returns the number of fields in the message.
        Alias for field_count() to match simplefix API.

        :return: Number of fields
        """
        return self.field_count()
