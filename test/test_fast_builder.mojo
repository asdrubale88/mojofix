"""Test FastBuilder functionality."""

from mojofix.experimental.hft import FastBuilder
from testing import assert_equal, assert_true


fn test_basic_building() raises:
    """Test basic message building."""
    var builder = FastBuilder()
    builder.append_pair(8, "FIX.4.2")
    builder.append_pair(35, "D")
    builder.append_pair(49, "SENDER")
    builder.append_pair(56, "TARGET")
    builder.append_pair(55, "AAPL")

    var msg = builder.encode()

    # Check that message contains expected fields
    assert_true(msg.find("8=FIX.4.2") != -1, "BeginString not found")
    assert_true(msg.find("35=D") != -1, "MsgType not found")
    assert_true(msg.find("49=SENDER") != -1, "SenderCompID not found")
    assert_true(msg.find("56=TARGET") != -1, "TargetCompID not found")
    assert_true(msg.find("55=AAPL") != -1, "Symbol not found")
    assert_true(msg.find("9=") != -1, "BodyLength not found")
    assert_true(msg.find("10=") != -1, "Checksum not found")

    print("✓ test_basic_building passed")


fn test_integer_values() raises:
    """Test integer value appending."""
    var builder = FastBuilder()
    builder.append_pair(8, "FIX.4.2")
    builder.append_pair(35, "D")
    builder.append_pair(54, 1)  # Side = Buy
    builder.append_pair(38, 100)  # OrderQty

    var msg = builder.encode()

    assert_true(msg.find("54=1") != -1, "Side not found")
    assert_true(msg.find("38=100") != -1, "OrderQty not found")

    print("✓ test_integer_values passed")


fn test_float_values() raises:
    """Test float value appending."""
    var builder = FastBuilder()
    builder.append_pair(8, "FIX.4.2")
    builder.append_pair(35, "D")
    builder.append_pair(44, 150.50)  # Price

    var msg = builder.encode()

    assert_true(msg.find("44=150.5") != -1, "Price not found")

    print("✓ test_float_values passed")


fn test_boolean_values() raises:
    """Test boolean value appending."""
    var builder = FastBuilder()
    builder.append_pair(8, "FIX.4.2")
    builder.append_pair(35, "D")
    builder.append_pair(114, True)  # LocateReqd = Y
    builder.append_pair(115, False)  # OnBehalfOfCompID = N

    var msg = builder.encode()

    assert_true(msg.find("114=Y") != -1, "LocateReqd not found")
    assert_true(msg.find("115=N") != -1, "OnBehalfOfCompID not found")

    print("✓ test_boolean_values passed")


fn test_buffer_reuse() raises:
    """Test buffer reuse with reset()."""
    var builder = FastBuilder()

    # Build first message
    builder.append_pair(8, "FIX.4.2")
    builder.append_pair(35, "D")
    builder.append_pair(55, "AAPL")
    var msg1 = builder.encode()

    # Reset and build second message
    builder.reset()
    builder.append_pair(8, "FIX.4.2")
    builder.append_pair(35, "D")
    builder.append_pair(55, "MSFT")
    var msg2 = builder.encode()

    # Messages should be different
    assert_true(msg1.find("55=AAPL") != -1, "First message missing AAPL")
    assert_true(msg2.find("55=MSFT") != -1, "Second message missing MSFT")
    assert_true(msg2.find("55=AAPL") == -1, "Second message contains AAPL")

    print("✓ test_buffer_reuse passed")


fn test_raw_data_field() raises:
    """Test raw data field with length prefix."""
    var builder = FastBuilder()
    builder.append_pair(8, "FIX.4.2")
    builder.append_pair(35, "D")
    builder.append_data(91, 90, "BINARY_DATA")

    var msg = builder.encode()

    assert_true(msg.find("91=11") != -1, "SecDataLen not found")
    assert_true(msg.find("90=BINARY_DATA") != -1, "SecData not found")

    print("✓ test_raw_data_field passed")


fn test_large_message() raises:
    """Test building large message with many fields."""
    var builder = FastBuilder()
    builder.append_pair(8, "FIX.4.2")
    builder.append_pair(35, "D")

    # Add 50 fields
    for i in range(50):
        builder.append_pair(5000 + i, String(i))

    var msg = builder.encode()

    # Check a few fields
    assert_true(msg.find("5000=0") != -1, "Field 5000 not found")
    assert_true(msg.find("5025=25") != -1, "Field 5025 not found")
    assert_true(msg.find("5049=49") != -1, "Field 5049 not found")

    print("✓ test_large_message passed")


fn main() raises:
    print("=" * 70)
    print("FASTBUILDER TESTS")
    print("=" * 70)

    test_basic_building()
    test_integer_values()
    test_float_values()
    test_boolean_values()
    test_buffer_reuse()
    test_raw_data_field()
    test_large_message()

    print("\n" + "=" * 70)
    print("ALL TESTS PASSED ✓")
    print("=" * 70)
