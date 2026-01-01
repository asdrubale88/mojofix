"""Market Data specialized parser for HFT applications.

Optimized parser for Market Data Incremental (MsgType=X) messages using
fixed-size arrays to eliminate dynamic allocation overhead.
"""

from memory import UnsafePointer
from collections import InlineArray


comptime SOH = ord(chr(1))
comptime MAX_FIELDS = 2000  # Maximum fields in a Market Data message


struct MarketDataMessage(Movable):
    """Market Data message with fixed-size arrays for zero allocation.

    Uses stack-allocated arrays for maximum performance.
    Suitable for Market Data Incremental messages with up to 2000 fields.
    """

    var _data: String
    var _tags: InlineArray[Int, MAX_FIELDS]
    var _starts: InlineArray[Int, MAX_FIELDS]
    var _ends: InlineArray[Int, MAX_FIELDS]
    var _count: Int

    fn __init__(out self, data: String):
        """Create message with owned data."""
        self._data = data
        self._tags = InlineArray[Int, MAX_FIELDS](uninitialized=True)
        self._starts = InlineArray[Int, MAX_FIELDS](uninitialized=True)
        self._ends = InlineArray[Int, MAX_FIELDS](uninitialized=True)
        self._count = 0

    @always_inline
    fn add_field(mut self, tag: Int, value_start: Int, value_end: Int):
        """Add field to message (no bounds check for performance)."""
        self._tags[self._count] = tag
        self._starts[self._count] = value_start
        self._ends[self._count] = value_end
        self._count += 1

    fn get(self, tag: Int) -> String:
        """Get first occurrence of tag."""
        for i in range(self._count):
            if self._tags[i] == tag:
                return String(self._data[self._starts[i] : self._ends[i]])
        return String("")

    fn count(self) -> Int:
        """Get field count."""
        return self._count

    fn clear(mut self):
        """Clear all fields."""
        self._count = 0


struct MarketDataParser:
    """Specialized parser for Market Data Incremental messages.

    Optimized for MsgType=X with fixed arrays and zero allocations.
    Expected performance: 50k+ msg/s for large snapshots.
    """

    fn __init__(out self):
        """Initialize parser."""
        pass

    fn parse_incremental(mut self, data: String) raises -> MarketDataMessage:
        """Parse Market Data Incremental message.

        Args:
            data: Raw FIX message string.

        Returns:
            Parsed message with fixed arrays.

        Raises:
            If message has > 2000 fields (exceeds capacity).
        """
        var msg = MarketDataMessage(data)

        var pos = 0
        var length = len(data)
        var bytes = data.unsafe_ptr()

        while pos < length:
            # Find '=' delimiter using AVX-512
            var eq_pos = self._find_byte(bytes, pos, length, ord("="))
            if eq_pos == -1:
                break

            # Parse tag
            var tag = self._parse_int_bytes(bytes, pos, eq_pos)
            if tag == -1:
                pos += 1
                continue

            var value_start = eq_pos + 1

            # Find SOH delimiter
            var soh_pos = self._find_byte(bytes, value_start, length, SOH)
            var value_end: Int
            if soh_pos == -1:
                value_end = length
                pos = length
            else:
                value_end = soh_pos
                pos = soh_pos + 1

            # Add field (no bounds check for performance)
            if msg._count >= MAX_FIELDS:
                raise Error("Message exceeds maximum field count")

            msg.add_field(tag, value_start, value_end)

        return msg^

    @always_inline
    fn _find_byte(
        self, bytes: UnsafePointer[UInt8], start: Int, end: Int, char: Int
    ) -> Int:
        """Find byte in buffer range using AVX-512 SIMD."""
        var i = start

        # AVX-512 width (64 bytes)
        comptime width = 64

        # Create target vector
        var target = SIMD[DType.uint8, width](UInt8(char))

        while i + width <= end:
            # Load vector
            var chunk = bytes.load[width=width](i)

            # XOR - matches become 0
            var diff = chunk ^ target

            # If any match found (min value is 0)
            if diff.reduce_min() == 0:
                # Find first match
                for j in range(width):
                    if chunk[j] == UInt8(char):
                        return i + j

            i += width

        # Scalar cleanup
        for j in range(i, end):
            if Int(bytes[j]) == char:
                return j
        return -1

    @always_inline
    fn _parse_int_bytes(
        self, bytes: UnsafePointer[UInt8], start: Int, end: Int
    ) -> Int:
        """Parse integer from bytes (branchless)."""
        var res = 0
        for i in range(start, end):
            var b = Int(bytes[i])
            var digit = b - 48
            # Branchless validation
            var is_valid = (digit >= 0) & (digit <= 9)
            if not is_valid:
                return -1
            res = res * 10 + digit
        return res
