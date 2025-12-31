"""Fast FIX parser using owned types.

Optimized parser that uses owned types for safety while maintaining
good performance characteristics.
"""

from collections import List
from memory import UnsafePointer
from mojofix.experimental.hft.fast_message import FastMessage


comptime SOH = ord(chr(1))


struct FastParser:
    """Fast FIX parser using owned types.

    Key optimizations:
    - Minimal string allocations
    - Direct integer parsing
    - Handles raw data fields (SecData, Signature, etc.)
    - SWAR delimiter scanning

    Expected performance: >8M msg/s.
    """

    var raw_len_tags: List[Int]
    var raw_data_tags: List[Int]
    var soh_str: String

    fn __init__(out self):
        """Initialize parser."""
        self.raw_len_tags = List[Int]()
        self.raw_data_tags = List[Int]()
        self.soh_str = String(chr(1))

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

    fn parse_into(mut self, data: String, mut msg_in: FastMessage) raises:
        """Parse FIX message into existing message object.

        Args:
            data: Raw FIX message string.
            msg_in: Message object to populate (cleared before use).
        """
        msg_in._data = data
        msg_in.clear()

        var pos = 0
        var raw_len = 0
        var length = len(data)

        # Access bytes directly for speed
        var bytes = data.unsafe_ptr()

        while pos < length:
            # Find '=' delimiter using SWAR
            var eq_pos = self._find_byte(bytes, pos, length, ord("="))
            if eq_pos == -1:
                break

            # Parse tag
            var tag = self._parse_int_bytes(bytes, pos, eq_pos)
            if tag == -1:
                pos += 1
                continue

            # Check if this is a raw data tag
            var is_raw_data = False
            for i in range(len(self.raw_data_tags)):
                if tag == self.raw_data_tags[i]:
                    is_raw_data = True
                    break

            var value_start = eq_pos + 1
            var value_end: Int

            if is_raw_data and raw_len > 0:
                # Raw data field: read exactly raw_len bytes
                value_end = value_start + raw_len
                if value_end > length:
                    break
                pos = value_end + 1  # Skip SOH
                raw_len = 0
            else:
                # Normal field: find SOH using SWAR
                var soh_pos = self._find_byte(bytes, value_start, length, SOH)
                if soh_pos == -1:
                    value_end = length
                    pos = length
                else:
                    value_end = soh_pos
                    pos = soh_pos + 1

            # Store field indices
            msg_in.add_field(tag, value_start, value_end)

            # Check if this is a raw length tag
            var is_raw_len = False
            for i in range(len(self.raw_len_tags)):
                if tag == self.raw_len_tags[i]:
                    is_raw_len = True
                    break

            if is_raw_len:
                # Optimized zero-copy parsing
                raw_len = self._parse_int_bytes(bytes, value_start, value_end)

    fn parse(mut self, data: String) raises -> FastMessage:
        """Parse FIX message into new message object (convenience)."""
        var msg = FastMessage(data)
        self.parse_into(data, msg)
        return msg^

    @always_inline
    fn _find_byte(
        self, bytes: UnsafePointer[UInt8], start: Int, end: Int, char: Int
    ) -> Int:
        """Find byte in buffer range using SIMD."""
        var i = start

        # Vector width (AVX2 friendly)
        comptime width = 32

        # Create target vector
        var target = SIMD[DType.uint8, width](UInt8(char))

        while i + width <= end:
            # Load vector
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

    fn _parse_int_bytes(
        self, bytes: UnsafePointer[UInt8], start: Int, end: Int
    ) -> Int:
        """Parse integer from bytes."""
        var res = 0
        for i in range(start, end):
            var b = Int(bytes[i])
            if b < 48 or b > 57:  # not '0'-'9'
                return -1
            res = res * 10 + (b - 48)
        return res

    fn _find_char(self, data: String, start: Int, end: Int, char: Int) -> Int:
        var data_bytes = data.as_bytes()
        for i in range(start, end):
            if Int(data_bytes[i]) == char:
                return i
        return -1

    fn _parse_int(self, data: String, start: Int, end: Int) -> Int:
        """Parse integer from string range.

        Args:
            data: Data string.
            start: Start position.
            end: End position (exclusive).

        Returns:
            Parsed integer, or -1 on error.
        """
        var result = 0
        var negative = False
        var i = start
        var data_bytes = data.as_bytes()

        if i < end and data_bytes[i] == ord("-"):
            negative = True
            i += 1

        if i >= end:
            return -1

        while i < end:
            var digit = Int(data_bytes[i]) - ord("0")
            if digit < 0 or digit > 9:
                return -1
            result = result * 10 + digit
            i += 1

        return -result if negative else result
