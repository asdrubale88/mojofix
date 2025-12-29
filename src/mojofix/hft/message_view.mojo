"""Zero-copy FIX message view for HFT.

⚠️ WARNING: MessageView does not own its data.
The arena must remain valid for the lifetime of all views.
"""

from memory import UnsafePointer
from mojofix.hft.string_view import StringView
from mojofix.hft.arena import Arena


struct FieldView(Copyable):
    """Non-owning view of a FIX field (tag=value)."""

    var tag: Int
    var value: StringView

    fn __init__(out self, tag: Int, value: StringView):
        self.tag = tag
        self.value = value

    fn __copyinit__(out self, existing: Self):
        """Copy constructor."""
        self.tag = existing.tag
        self.value = existing.value


struct MessageView:
    """Zero-copy view of a parsed FIX message.

    ⚠️ SAFETY: This struct does not own its data.
    - The arena must outlive this MessageView
    - Do not modify arena while MessageView is in use
    - Fields are stored as raw pointers for speed
    """

    var fields: UnsafePointer[FieldView]
    var count: Int
    var capacity: Int

    fn __init__(out self, capacity: Int = 64):
        """Create message view with field capacity.

        Args:
            capacity: Maximum number of fields.
        """
        self.capacity = capacity
        self.count = 0
        self.fields = UnsafePointer[FieldView].alloc(capacity)

    fn __del__(deinit self):
        """Free field array."""
        self.fields.free()

    fn add_field(mut self, tag: Int, value: StringView):
        """Add field to message (no bounds checking).

        ⚠️ UNSAFE: Caller must ensure capacity not exceeded.

        Args:
            tag: FIX tag number.
            value: Field value (view into arena).
        """
        self.fields[self.count] = FieldView(tag, value)
        self.count += 1

    fn get(self, tag: Int) -> StringView:
        """Get first occurrence of tag.

        Args:
            tag: FIX tag number.

        Returns:
            StringView of value, or empty view if not found.
        """
        for i in range(self.count):
            if self.fields[i].tag == tag:
                return self.fields[i].value

        return StringView()

    fn get_nth(self, tag: Int, nth: Int) -> StringView:
        """Get nth occurrence of tag (1-indexed).

        Args:
            tag: FIX tag number.
            nth: Which occurrence (1 = first).

        Returns:
            StringView of value, or empty view if not found.
        """
        var found = 0
        for i in range(self.count):
            if self.fields[i].tag == tag:
                found += 1
                if found == nth:
                    return self.fields[i].value

        return StringView()

    fn has_field(self, tag: Int) -> Bool:
        """Check if tag exists in message.

        Args:
            tag: FIX tag number.

        Returns:
            True if tag exists.
        """
        for i in range(self.count):
            if self.fields[i].tag == tag:
                return True
        return False

    fn field_count(self) -> Int:
        """Get number of fields in message."""
        return self.count

    fn reset(mut self):
        """Reset message to empty (reuse allocation)."""
        self.count = 0
