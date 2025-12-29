"""Test suite for HFT zero-copy module."""

from mojofix.hft import ArenaParser, MessageView, StringView
from testing import assert_equal, assert_true, assert_false


fn test_arena_parser_basic() raises:
    """Test basic parsing with ArenaParser."""
    print("Test: arena_parser_basic...")

    var parser = ArenaParser()
    var msg_str = (
        "8=FIX.4.2\x019=40\x0135=D\x0155=AAPL\x0154=1\x0138=100\x0110=000\x01"
    )

    var msg = parser.parse_message(msg_str)

    # Check field count
    assert_true(msg.field_count() > 0, "Message should have fields")

    # Check specific fields
    var begin_string = msg.get(8)
    assert_true(
        begin_string.equals_string("FIX.4.2"), "BeginString should be FIX.4.2"
    )

    var msg_type = msg.get(35)
    assert_true(msg_type.equals_string("D"), "MsgType should be D")

    var symbol = msg.get(55)
    assert_true(symbol.equals_string("AAPL"), "Symbol should be AAPL")

    print("✓ PASS")


fn test_string_view_comparison() raises:
    """Test StringView comparison operations."""
    print("Test: string_view_comparison...")

    var parser = ArenaParser()
    var msg1 = parser.parse_message("8=FIX.4.2\x0155=AAPL\x01")
    var msg2 = parser.parse_message("8=FIX.4.2\x0155=MSFT\x01")

    var symbol1 = msg1.get(55)
    var symbol2 = msg2.get(55)

    assert_true(symbol1 != symbol2, "Different symbols should not be equal")
    assert_true(symbol1 < symbol2, "AAPL should be less than MSFT")

    print("✓ PASS")


fn test_arena_reset() raises:
    """Test arena reset functionality."""
    print("Test: arena_reset...")

    var parser = ArenaParser()

    # Parse first message
    var msg1 = parser.parse_message("8=FIX.4.2\x0155=AAPL\x01")
    var used_before = parser.arena.used()

    # Reset arena
    parser.reset_arena()
    assert_equal(parser.arena.used(), 0, "Arena should be empty after reset")

    # Parse second message
    var msg2 = parser.parse_message("8=FIX.4.2\x0155=MSFT\x01")
    assert_true(
        parser.arena.used() > 0, "Arena should have data after second parse"
    )

    print("✓ PASS")


fn test_raw_data_fields() raises:
    """Test parsing of raw data fields with embedded SOH."""
    print("Test: raw_data_fields...")

    var parser = ArenaParser()

    # Message with SecData (91/90) containing embedded SOH
    var raw_data = "BINARY\x01DATA"  # Contains SOH
    var msg_str = "8=FIX.4.2\x0191=11\x0190=" + raw_data + "\x0155=AAPL\x01"

    var msg = parser.parse_message(msg_str)

    # Check that raw data is preserved
    var sec_data = msg.get(90)
    assert_equal(sec_data.length, 11, "SecData length should be 11")
    assert_true(
        sec_data.equals_string(raw_data), "SecData should preserve embedded SOH"
    )

    # Check that subsequent field is parsed correctly
    var symbol = msg.get(55)
    assert_true(symbol.equals_string("AAPL"), "Symbol should be AAPL")

    print("✓ PASS")


fn test_message_view_get_nth() raises:
    """Test getting nth occurrence of repeating tags."""
    print("Test: message_view_get_nth...")

    var parser = ArenaParser()
    var msg_str = "8=FIX.4.2\x0155=AAPL\x0155=MSFT\x0155=GOOG\x01"

    var msg = parser.parse_message(msg_str)

    var symbol1 = msg.get_nth(55, 1)
    assert_true(symbol1.equals_string("AAPL"), "First symbol should be AAPL")

    var symbol2 = msg.get_nth(55, 2)
    assert_true(symbol2.equals_string("MSFT"), "Second symbol should be MSFT")

    var symbol3 = msg.get_nth(55, 3)
    assert_true(symbol3.equals_string("GOOG"), "Third symbol should be GOOG")

    print("✓ PASS")


fn main() raises:
    print("=" * 60)
    print("HFT MODULE TEST SUITE")
    print("=" * 60)

    test_arena_parser_basic()
    test_string_view_comparison()
    test_arena_reset()
    test_raw_data_fields()
    test_message_view_get_nth()

    print("\n" + "=" * 60)
    print("✅ ALL HFT TESTS PASSED!")
    print("=" * 60)
