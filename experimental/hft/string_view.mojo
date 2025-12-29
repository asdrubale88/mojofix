"""Zero-copy string view for HFT parsing.

⚠️ WARNING: StringView does not own its data.
The underlying buffer must remain valid for the lifetime of the view.
"""

from memory import UnsafePointer


struct StringView(Comparable, Copyable, Stringable):
    """Non-owning view into a string buffer.

    Similar to C++ std::string_view or Rust &str.
    """

    var data: UnsafePointer[UInt8]
    var length: Int

    fn __init__(out self):
        """Create empty view."""
        self.data = UnsafePointer[UInt8]()
        self.length = 0

    fn __init__(out self, data: UnsafePointer[UInt8], length: Int):
        """Create view from pointer and length.

        Args:
            data: Pointer to string data.
            length: Length in bytes.
        """
        self.data = data
        self.length = length

    fn __copyinit__(out self, existing: Self):
        """Copy constructor."""
        self.data = existing.data
        self.length = existing.length

    fn __len__(self) -> Int:
        """Get length of string view."""
        return self.length

    fn __getitem__(self, index: Int) -> UInt8:
        """Get byte at index (no bounds checking).

        ⚠️ UNSAFE: No bounds checking for performance.
        """
        return self.data[index]

    fn __str__(self) -> String:
        """Convert to owned String (allocates).

        Use sparingly - defeats zero-copy purpose.
        """
        if self.length == 0:
            return String("")

        var result = String("")
        for i in range(self.length):
            result += chr(Int(self.data[i]))
        return result

    fn __eq__(self, other: StringView) -> Bool:
        """Compare two string views for equality."""
        if self.length != other.length:
            return False

        for i in range(self.length):
            if self.data[i] != other.data[i]:
                return False

        return True

    fn __ne__(self, other: StringView) -> Bool:
        """Compare two string views for inequality."""
        return not (self == other)

    fn __lt__(self, other: StringView) -> Bool:
        """Lexicographic comparison."""
        var min_len = (
            self.length if self.length < other.length else other.length
        )

        for i in range(min_len):
            if self.data[i] < other.data[i]:
                return True
            elif self.data[i] > other.data[i]:
                return False

        return self.length < other.length

    fn __le__(self, other: StringView) -> Bool:
        """Less than or equal comparison."""
        return self < other or self == other

    fn __gt__(self, other: StringView) -> Bool:
        """Greater than comparison."""
        return not (self <= other)

    fn __ge__(self, other: StringView) -> Bool:
        """Greater than or equal comparison."""
        return not (self < other)

    fn equals_string(self, s: String) -> Bool:
        """Compare with owned String.

        Args:
            s: String to compare with.

        Returns:
            True if contents match.
        """
        if self.length != len(s):
            return False

        var s_bytes = s.as_bytes()
        for i in range(self.length):
            if self.data[i] != s_bytes[i]:
                return False

        return True

    fn to_int(self) raises -> Int:
        """Parse view as integer.

        Returns:
            Parsed integer value.

        Raises:
            Error if not a valid integer.
        """
        # Convert to String first (temporary allocation)
        return Int(str(self))

    fn is_empty(self) -> Bool:
        """Check if view is empty."""
        return self.length == 0
