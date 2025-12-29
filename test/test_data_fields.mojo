from testing import assert_equal
from mojofix.message import FixMessage, SOH


fn test_append_data() raises:
    print("Testing append_data for raw data fields...")
    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "D")

    # Add raw data with embedded SOH
    var raw_data = String("binary") + String(SOH) + "data"
    msg.append_data(91, 90, raw_data)  # SecData

    # Verify length field was added
    var sec_data_len = msg.get(91)
    if sec_data_len:
        assert_equal(sec_data_len.value(), String(len(raw_data)))
    else:
        raise Error("SecDataLen should exist")

    # Verify data field was added
    var sec_data = msg.get(90)
    if sec_data:
        assert_equal(sec_data.value(), raw_data)
    else:
        raise Error("SecData should exist")

    print("✓ append_data test passed")


fn test_signature_field() raises:
    print("Testing Signature field (93/89)...")
    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "A")

    var signature = "SIGNATURE" + String(SOH) + "DATA"
    msg.append_data(93, 89, signature)

    if msg.get(93):
        assert_equal(msg.get(93).value(), String(len(signature)))
    if msg.get(89):
        assert_equal(msg.get(89).value(), signature)

    print("✓ Signature field test passed")


fn main() raises:
    test_append_data()
    test_signature_field()
    print("\nAll raw data field tests passed!")
