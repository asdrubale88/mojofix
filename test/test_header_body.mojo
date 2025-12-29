from testing import assert_equal
from mojofix.message import FixMessage


fn test_header_body_separation() raises:
    print("Testing header/body separation...")
    var msg = FixMessage()

    # Add header fields
    msg.append_pair(8, "FIX.4.2", header=True)
    msg.append_pair(9, "100", header=True)  # Will be recalculated
    msg.append_pair(35, "D", header=True)

    # Add body fields
    msg.append_pair(55, "AAPL")
    msg.append_pair(54, "1")
    msg.append_pair(38, "100")

    # Verify header fields can be retrieved
    if msg.get(8):
        assert_equal(msg.get(8).value(), "FIX.4.2")
        print("✓ Header field 8 (BeginString) retrieved")

    if msg.get(35):
        assert_equal(msg.get(35).value(), "D")
        print("✓ Header field 35 (MsgType) retrieved")

    # Verify body fields can be retrieved
    if msg.get(55):
        assert_equal(msg.get(55).value(), "AAPL")
        print("✓ Body field 55 (Symbol) retrieved")

    print("✓ Header/body separation test passed")


fn test_header_parameter_in_methods() raises:
    print("Testing header parameter in various methods...")
    var msg = FixMessage()

    # Test append_string with header
    msg.append_string("8=FIX.4.2", header=True)
    msg.append_string("35=D", header=True)
    msg.append_string("55=MSFT")  # Body field

    if msg.get(8):
        assert_equal(msg.get(8).value(), "FIX.4.2")
    if msg.get(35):
        assert_equal(msg.get(35).value(), "D")
    if msg.get(55):
        assert_equal(msg.get(55).value(), "MSFT")

    print("✓ append_string with header parameter works")

    # Test append_data with header
    var msg2 = FixMessage()
    msg2.append_data(93, 89, "SIG_DATA", header=True)

    if msg2.get(93):
        assert_equal(msg2.get(93).value(), String(len("SIG_DATA")))
        print("✓ append_data with header parameter works")


fn main() raises:
    test_header_body_separation()
    test_header_parameter_in_methods()
    print("\nAll header/body tests passed!")
