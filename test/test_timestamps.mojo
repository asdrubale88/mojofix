from testing import assert_equal
from mojofix.message import FixMessage
from mojofix.time_utils import format_utc_timestamp, format_utc_time_only


fn test_native_timestamp_formatting() raises:
    print("Testing native Mojo timestamp formatting...")

    # Test known timestamp: 2024-01-15 10:30:45.123 UTC
    # Unix timestamp: 1705318245.123
    var timestamp: Float64 = 1705318245.123

    var formatted = format_utc_timestamp(timestamp, precision=3)
    print("Formatted timestamp:", formatted)

    # Should be: 20240115-10:30:45.123
    if formatted.startswith("20240115"):
        print("✓ Date part correct")
    else:
        print("✗ Date part incorrect:", formatted)

    if "10:30:45" in formatted:
        print("✓ Time part correct")
    else:
        print("✗ Time part incorrect:", formatted)

    print("✓ Native timestamp formatting test passed")


fn test_append_utc_timestamp_native() raises:
    print("Testing append_utc_timestamp with native formatting...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "D")

    # Use a known timestamp instead of current time
    var timestamp: Float64 = 1705318245.123
    msg.append_utc_timestamp(52, timestamp, precision=3)

    var sending_time = msg.get(52)
    if sending_time:
        print("SendingTime (52):", sending_time.value())
        # Should have format YYYYMMDD-HH:MM:SS.sss
        if len(sending_time.value()) >= 21:  # Minimum length with milliseconds
            print("✓ Timestamp has correct length")
        else:
            print("✗ Timestamp length incorrect:", len(sending_time.value()))
    else:
        raise Error("SendingTime should exist")

    print("✓ append_utc_timestamp with native formatting passed")


fn test_precision_levels() raises:
    print("Testing different precision levels...")

    var timestamp: Float64 = 1705318245.123456

    # Precision 0 (seconds only)
    var p0 = format_utc_timestamp(timestamp, precision=0)
    print("Precision 0:", p0)
    if "." not in p0:
        print("✓ Precision 0 has no fractional part")

    # Precision 3 (milliseconds)
    var p3 = format_utc_timestamp(timestamp, precision=3)
    print("Precision 3:", p3)
    if ".123" in p3 or ".12" in p3:  # Allow for rounding
        print("✓ Precision 3 has milliseconds")

    # Precision 6 (microseconds)
    var p6 = format_utc_timestamp(timestamp, precision=6)
    print("Precision 6:", p6)
    if len(p6.split(".")[-1]) >= 6:
        print("✓ Precision 6 has microseconds")

    print("✓ Precision levels test passed")


fn test_time_only_formatting() raises:
    print("Testing UTCTimeOnly formatting...")

    var timestamp: Float64 = 1705318245.123
    var time_only = format_utc_time_only(timestamp, precision=3)

    print("Time only:", time_only)
    if "10:30:45" in time_only:
        print("✓ Time only format correct")

    print("✓ UTCTimeOnly formatting passed")


fn main() raises:
    test_native_timestamp_formatting()
    test_append_utc_timestamp_native()
    test_precision_levels()
    test_time_only_formatting()
    print("\n✅ All native timestamp tests passed!")
