from testing import assert_equal, assert_true
from mojofix.message import FixMessage, SOH


fn test_basic_message() raises:
    print("Testing basic message creation...")
    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "D")
    msg.append_pair(55, "AAPL")
    msg.append_pair(54, "1")
    msg.append_pair(38, "100")
    msg.append_pair(44, "150.50")

    var encoded = msg.encode()
    print("Encoded:", encoded)

    # Verify structure
    var soh_str = String(SOH)
    var expected_start = String("8=FIX.4.2") + soh_str
    assert_true(encoded.startswith(expected_start), "Header start wrong")

    var expected_35 = String("35=D") + soh_str
    assert_true(encoded.find(expected_35) != -1, "MsgType missing")

    var expected_55 = String("55=AAPL") + soh_str
    assert_true(encoded.find(expected_55) != -1, "Symbol missing")

    var expected_end = soh_str
    assert_true(encoded.endswith(expected_end), "Message must end with SOH")

    # Verify checksum presence
    assert_true(encoded.find("10=") != -1, "Checksum tag missing")


fn test_encode_raw() raises:
    print("Testing raw encode...")
    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "A")
    var raw = msg.encode(True)
    var soh_str = String(SOH)
    var expected = String("8=FIX.4.2") + soh_str + "35=A" + soh_str
    assert_equal(raw, expected)


fn main() raises:
    test_basic_message()
    test_encode_raw()
