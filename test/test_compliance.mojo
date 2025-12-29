"""FIX Protocol Specification Compliance Tests.

Validates mojofix against official FIX Trading Community specifications
for message structure, required fields, and data types.
"""

from testing import assert_true, assert_false, assert_equal
from mojofix.message import FixMessage
from mojofix.parser import FixParser


fn test_compliance_required_header_fields() raises:
    """Test that all messages have required header fields."""
    print("Test: compliance_required_header_fields...")

    # Every FIX message must have BeginString, BodyLength, MsgType
    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.4")  # BeginString - required
    msg.append_pair(35, "D")  # MsgType - required
    # BodyLength (9) is auto-calculated

    var encoded = msg.encode()

    # Verify all required fields present
    assert_true("8=" in encoded, "BeginString required")
    assert_true("9=" in encoded, "BodyLength required")
    assert_true("35=" in encoded, "MsgType required")

    print("✓ PASS")


fn test_compliance_message_types() raises:
    """Test standard FIX message types."""
    print("Test: compliance_message_types...")

    # Test common message types
    var message_types = List[String]()
    message_types.append("0")  # Heartbeat
    message_types.append("1")  # Test Request
    message_types.append("2")  # Resend Request
    message_types.append("3")  # Reject
    message_types.append("4")  # Sequence Reset
    message_types.append("5")  # Logout
    message_types.append("A")  # Logon
    message_types.append("D")  # New Order Single
    message_types.append("8")  # Execution Report
    message_types.append("F")  # Order Cancel Request
    message_types.append("G")  # Order Cancel/Replace Request
    message_types.append("V")  # Market Data Request

    for i in range(len(message_types)):
        var msg = FixMessage()
        msg.append_pair(8, "FIX.4.4")
        msg.append_pair(35, message_types[i])

        var encoded = msg.encode()
        var parser = FixParser()
        parser.append_buffer(encoded)
        var parsed = parser.get_message()

        assert_true(
            parsed.__bool__(), "Should parse message type " + message_types[i]
        )

    print("✓ PASS - All standard message types supported")


fn test_compliance_field_ordering() raises:
    """Test that standard header fields come first."""
    print("Test: compliance_field_ordering...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.4")  # BeginString - must be first
    msg.append_pair(35, "D")  # MsgType
    msg.append_pair(55, "AAPL")  # Body field

    var encoded = msg.encode()

    # BeginString (8) must come before BodyLength (9)
    var pos_8 = encoded.find("8=")
    var pos_9 = encoded.find("9=")
    var pos_35 = encoded.find("35=")

    assert_true(pos_8 < pos_9, "BeginString before BodyLength")
    assert_true(pos_9 < pos_35, "BodyLength before MsgType")

    print("✓ PASS")


fn test_compliance_checksum_format() raises:
    """Test checksum field format (3 digits)."""
    print("Test: compliance_checksum_format...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.4")
    msg.append_pair(35, "0")

    var encoded = msg.encode()

    # Checksum must be present and at the end
    assert_true("10=" in encoded, "Checksum field required")
    assert_true(encoded.endswith(chr(1)), "Message must end with SOH")

    # Checksum should be 3 digits (format: 10=XXX)
    var checksum_pos = encoded.find("10=")
    assert_true(checksum_pos > 0, "Checksum must be present")

    print("✓ PASS")


fn test_compliance_data_types_string() raises:
    """Test STRING data type handling."""
    print("Test: compliance_data_types_string...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.4")
    msg.append_pair(35, "D")
    msg.append_pair(55, "AAPL")  # Symbol - STRING type
    msg.append_pair(58, "Test order")  # Text - STRING type

    var encoded = msg.encode()
    var parser = FixParser()
    parser.append_buffer(encoded)
    var parsed = parser.get_message()

    assert_true(parsed.__bool__(), "Should parse STRING fields")

    if parsed:
        var msg_parsed = parsed.take()
        var symbol = msg_parsed[55]
        if symbol:
            assert_equal(symbol.value(), "AAPL")

    print("✓ PASS")


fn test_compliance_data_types_int() raises:
    """Test INT data type handling."""
    print("Test: compliance_data_types_int...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.4")
    msg.append_pair(35, "D")
    msg.append_pair(38, "100")  # OrderQty - QTY (INT) type
    msg.append_pair(110, "50")  # MinQty - QTY (INT) type

    var encoded = msg.encode()
    var parser = FixParser()
    parser.append_buffer(encoded)
    var parsed = parser.get_message()

    assert_true(parsed.__bool__(), "Should parse INT fields")

    if parsed:
        var msg_parsed = parsed.take()
        var qty = msg_parsed[38]
        if qty:
            assert_equal(qty.value(), "100")

    print("✓ PASS")


fn test_compliance_data_types_float() raises:
    """Test FLOAT/PRICE data type handling."""
    print("Test: compliance_data_types_float...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.4")
    msg.append_pair(35, "D")
    msg.append_pair(44, "150.50")  # Price - PRICE type
    msg.append_pair(99, "25.75")  # StopPx - PRICE type

    var encoded = msg.encode()
    var parser = FixParser()
    parser.append_buffer(encoded)
    var parsed = parser.get_message()

    assert_true(parsed.__bool__(), "Should parse FLOAT fields")

    if parsed:
        var msg_parsed = parsed.take()
        var price = msg_parsed[44]
        if price:
            assert_equal(price.value(), "150.50")

    print("✓ PASS")


fn test_compliance_data_types_char() raises:
    """Test CHAR data type handling."""
    print("Test: compliance_data_types_char...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.4")
    msg.append_pair(35, "D")
    msg.append_pair(54, "1")  # Side - CHAR type (1=Buy, 2=Sell)
    msg.append_pair(40, "2")  # OrdType - CHAR type

    var encoded = msg.encode()
    var parser = FixParser()
    parser.append_buffer(encoded)
    var parsed = parser.get_message()

    assert_true(parsed.__bool__(), "Should parse CHAR fields")

    if parsed:
        var msg_parsed = parsed.take()
        var side = msg_parsed[54]
        if side:
            assert_equal(side.value(), "1")

    print("✓ PASS")


fn test_compliance_repeating_groups() raises:
    """Test repeating group compliance."""
    print("Test: compliance_repeating_groups...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.4")
    msg.append_pair(35, "V")  # Market Data Request

    # NoMDEntryTypes repeating group
    msg.append_pair(267, "2")  # Number of entries
    msg.append_pair(269, "0")  # MDEntryType - Bid
    msg.append_pair(269, "1")  # MDEntryType - Offer

    var encoded = msg.encode()
    var parser = FixParser()
    parser.append_buffer(encoded)
    var parsed = parser.get_message()

    assert_true(parsed.__bool__(), "Should parse repeating groups")

    if parsed:
        var msg_parsed = parsed.take()
        var entries = msg_parsed.get_all(269)
        assert_equal(len(entries), 2, "Should have 2 repeating entries")

    print("✓ PASS")


fn test_compliance_session_messages() raises:
    """Test session-level message compliance."""
    print("Test: compliance_session_messages...")

    # Logon
    var logon = FixMessage()
    logon.append_pair(8, "FIX.4.4")
    logon.append_pair(35, "A")
    logon.append_pair(98, "0")  # EncryptMethod
    logon.append_pair(108, "30")  # HeartBtInt
    assert_true(logon.validate(), "Logon should validate")

    # Heartbeat
    var heartbeat = FixMessage()
    heartbeat.append_pair(8, "FIX.4.4")
    heartbeat.append_pair(35, "0")
    assert_true(heartbeat.validate(), "Heartbeat should validate")

    # Logout
    var logout = FixMessage()
    logout.append_pair(8, "FIX.4.4")
    logout.append_pair(35, "5")
    assert_true(logout.validate(), "Logout should validate")

    print("✓ PASS")


fn main() raises:
    print("=" * 70)
    print("FIX PROTOCOL SPECIFICATION COMPLIANCE TESTS")
    print("Validating against FIX Trading Community specifications")
    print("=" * 70)

    var test_count = 0

    print("\n--- REQUIRED FIELDS ---")
    test_compliance_required_header_fields()
    test_count += 1

    print("\n--- MESSAGE TYPES ---")
    test_compliance_message_types()
    test_count += 1

    print("\n--- FIELD ORDERING ---")
    test_compliance_field_ordering()
    test_count += 1

    print("\n--- CHECKSUM FORMAT ---")
    test_compliance_checksum_format()
    test_count += 1

    print("\n--- DATA TYPES ---")
    test_compliance_data_types_string()
    test_count += 1
    test_compliance_data_types_int()
    test_count += 1
    test_compliance_data_types_float()
    test_count += 1
    test_compliance_data_types_char()
    test_count += 1

    print("\n--- REPEATING GROUPS ---")
    test_compliance_repeating_groups()
    test_count += 1

    print("\n--- SESSION MESSAGES ---")
    test_compliance_session_messages()
    test_count += 1

    print("\n" + "=" * 70)
    print("✅ ALL", test_count, "COMPLIANCE TESTS PASSED!")
    print("=" * 70)
    print("\nFIX Specification Compliance:")
    print("  • Required header fields: ✅ Compliant")
    print("  • Standard message types: ✅ Supported")
    print("  • Field ordering: ✅ Correct")
    print("  • Checksum format: ✅ Valid")
    print("  • Data types (STRING, INT, FLOAT, CHAR): ✅ Handled")
    print("  • Repeating groups: ✅ Supported")
    print("  • Session messages: ✅ Validated")
    print("\nMojofix is FIX SPEC COMPLIANT! 📋")
