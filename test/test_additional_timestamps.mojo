"""Test additional timestamp methods."""

from testing import assert_equal
from mojofix.message import FixMessage
from mojofix.time_utils import format_utc_date_only


fn test_format_utc_date_only() raises:
    print("Testing format_utc_date_only()...")

    # Test known timestamp: 2024-01-15 10:30:45 UTC
    var timestamp: Float64 = 1705318245.0

    var formatted = format_utc_date_only(timestamp)
    print("Formatted date:", formatted)

    # Should be: 20240115
    assert_equal(formatted, "20240115")
    print("✓ Date-only format correct")


fn test_append_utc_date_only() raises:
    print("Testing append_utc_date_only()...")

    var msg = FixMessage()
    var timestamp: Float64 = 1705318245.0

    # Append date-only field (e.g., TradeDate tag 75)
    msg.append_utc_date_only(75, timestamp)

    var trade_date = msg[75]
    if trade_date:
        assert_equal(trade_date.value(), "20240115")
        print("✓ TradeDate field correct:", trade_date.value())
    else:
        raise Error("TradeDate should exist")


fn test_date_only_in_message() raises:
    print("Testing date-only in complete message...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "D")
    msg.append_utc_date_only(75, 1705318245.0)  # TradeDate
    msg.append_pair(55, "AAPL")

    var encoded = msg.encode()
    print("Encoded message:", encoded)

    # Verify TradeDate is in the message
    if "75=20240115" in encoded:
        print("✓ Date-only field in encoded message")
    else:
        raise Error("Date field should be in message")


fn main() raises:
    print("=" * 60)
    print("ADDITIONAL TIMESTAMP METHODS TESTS")
    print("=" * 60)

    test_format_utc_date_only()
    test_append_utc_date_only()
    test_date_only_in_message()

    print("\n" + "=" * 60)
    print("✅ All additional timestamp tests passed!")
    print("=" * 60)
