"""Test suite for HFT fast parsing module."""

from mojofix.experimental.hft import FastParser, FastMessage
from testing import assert_equal, assert_true, assert_false


fn test_fast_parser_basic() raises:
    """Test basic parsing with FastParser."""
    print("Test: fast_parser_basic...")

    var parser = FastParser()
    var msg_str = (
        "8=FIX.4.2\x019=40\x0135=D\x0155=AAPL\x0154=1\x0138=100\x0110=000\x01"
    )

    var msg = parser.parse(msg_str)

    # Check field count
    assert_true(msg.field_count() > 0, "Message should have fields")

    # Check specific fields
    var begin_string = msg.get(8)
    assert_equal(begin_string, "FIX.4.2", "BeginString should be FIX.4.2")

    var msg_type = msg.get(35)
    assert_equal(msg_type, "D", "MsgType should be D")

    var symbol = msg.get(55)
    assert_equal(symbol, "AAPL", "Symbol should be AAPL")

    print("✓ PASS")


fn test_fast_message_get_nth() raises:
    """Test getting nth occurrence of repeating tags."""
    print("Test: fast_message_get_nth...")

    var parser = FastParser()
    var msg_str = "8=FIX.4.2\x0155=AAPL\x0155=MSFT\x0155=GOOG\x01"

    var msg = parser.parse(msg_str)

    var symbol1 = msg.get_nth(55, 1)
    assert_equal(symbol1, "AAPL", "First symbol should be AAPL")

    var symbol2 = msg.get_nth(55, 2)
    assert_equal(symbol2, "MSFT", "Second symbol should be MSFT")

    var symbol3 = msg.get_nth(55, 3)
    assert_equal(symbol3, "GOOG", "Third symbol should be GOOG")

    print("✓ PASS")


fn test_raw_data_fields() raises:
    """Test parsing of raw data fields with embedded SOH."""
    print("Test: raw_data_fields...")

    var parser = FastParser()

    # Message with SecData (91/90) containing embedded SOH
    var raw_data = "BINARY\x01DATA"  # Contains SOH
    var msg_str = "8=FIX.4.2\x0191=11\x0190=" + raw_data + "\x0155=AAPL\x01"

    var msg = parser.parse(msg_str)

    # Check that raw data is preserved
    var sec_data = msg.get(90)
    assert_equal(len(sec_data), 11, "SecData length should be 11")
    assert_equal(sec_data, raw_data, "SecData should preserve embedded SOH")

    # Check that subsequent field is parsed correctly
    var symbol = msg.get(55)
    assert_equal(symbol, "AAPL", "Symbol should be AAPL")

    print("✓ PASS")


fn test_has_field() raises:
    """Test has_field functionality."""
    print("Test: has_field...")

    var parser = FastParser()
    var msg_str = "8=FIX.4.2\x0135=D\x0155=AAPL\x01"

    var msg = parser.parse(msg_str)

    assert_true(msg.has_field(8), "Should have tag 8")
    assert_true(msg.has_field(35), "Should have tag 35")
    assert_true(msg.has_field(55), "Should have tag 55")
    assert_false(msg.has_field(999), "Should not have tag 999")

    print("✓ PASS")


fn main() raises:
    print("=" * 60)
    print("HFT FAST PARSER TEST SUITE")
    print("=" * 60)

    test_fast_parser_basic()
    test_fast_message_get_nth()
    test_raw_data_fields()
    test_has_field()

    print("\n" + "=" * 60)
    print("✅ ALL HFT TESTS PASSED!")
    print("=" * 60)
