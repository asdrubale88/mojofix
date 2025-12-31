"""Test Bool overload and has() method.

Tests the final convenience methods added for simplefix compatibility.
"""

from mojofix import FixMessage


fn test_bool_overload() raises:
    """Test append_pair Bool overload."""
    print("Testing Bool type conversion overload...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "D")

    # Test Bool overload - True should become "Y"
    msg.append_pair(141, True)  # ResetSeqNumFlag = Y
    msg.append_pair(93, False)  # SignatureLength = N

    # Verify True -> "Y"
    var reset_flag = msg.get(141)
    assert_true(reset_flag is not None, "ResetSeqNumFlag should exist")
    assert_equal(reset_flag.value(), "Y", "True should convert to 'Y'")

    # Verify False -> "N"
    var sig_len = msg.get(93)
    assert_true(sig_len is not None, "SignatureLength should exist")
    assert_equal(sig_len.value(), "N", "False should convert to 'N'")

    print("  ✅ Bool type conversion works correctly")


fn test_has_method() raises:
    """Test has() inline helper method."""
    print("Testing has() method...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "D")
    msg.append_pair(55, "AAPL")
    msg.append_pair(54, 1)

    # Test existing fields
    assert_true(msg.has(8), "Should have BeginString")
    assert_true(msg.has(35), "Should have MsgType")
    assert_true(msg.has(55), "Should have Symbol")
    assert_true(msg.has(54), "Should have Side")

    # Test missing fields
    assert_false(msg.has(999), "Should not have tag 999")
    assert_false(msg.has(1000), "Should not have tag 1000")
    assert_false(msg.has(44), "Should not have Price")

    print("  ✅ has() method works correctly")


fn test_has_with_conditional() raises:
    """Test has() method in conditional logic."""
    print("Testing has() in conditionals...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(55, "AAPL")
    msg.append_pair(44, "150.50")

    # Use has() in if statement
    var symbol_found = False
    if msg.has(55):
        symbol_found = True

    assert_true(symbol_found, "Symbol should be found")

    # Use has() to avoid Optional handling
    var price_value = ""
    if msg.has(44):
        price_value = msg.get(44).value()

    assert_equal(price_value, "150.50", "Price should be 150.50")

    # Test with missing field
    var missing_found = False
    if msg.has(999):
        missing_found = True

    assert_false(missing_found, "Missing field should not be found")

    print("  ✅ has() conditionals work correctly")


fn test_bool_and_has_combined() raises:
    """Test Bool overload and has() together."""
    print("Testing Bool overload + has() combined...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "D")

    # Add boolean fields
    msg.append_pair(141, True)  # ResetSeqNumFlag
    msg.append_pair(93, False)  # Another boolean

    # Check with has() and get value
    if msg.has(141):
        var reset = msg.get(141).value()
        assert_equal(reset, "Y", "ResetSeqNumFlag should be Y")
    else:
        raise Error("ResetSeqNumFlag should exist")

    if msg.has(93):
        var sig = msg.get(93).value()
        assert_equal(sig, "N", "Field 93 should be N")
    else:
        raise Error("Field 93 should exist")

    # Check missing field
    if msg.has(999):
        raise Error("Field 999 should not exist")

    print("  ✅ Combined usage works correctly")


fn test_all_type_overloads() raises:
    """Test all type conversion overloads together."""
    print("Testing all type overloads together...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")  # String
    msg.append_pair(35, "D")  # String
    msg.append_pair(55, "AAPL")  # String
    msg.append_pair(54, 1)  # Int
    msg.append_pair(38, 100)  # Int
    msg.append_pair(44, 150.50)  # Float64
    msg.append_pair(6, 99.99)  # Float64
    msg.append_pair(141, True)  # Bool
    msg.append_pair(93, False)  # Bool

    # Verify all fields exist
    assert_true(msg.has(8), "Should have BeginString")
    assert_true(msg.has(35), "Should have MsgType")
    assert_true(msg.has(55), "Should have Symbol")
    assert_true(msg.has(54), "Should have Side")
    assert_true(msg.has(38), "Should have OrderQty")
    assert_true(msg.has(44), "Should have Price")
    assert_true(msg.has(6), "Should have AvgPx")
    assert_true(msg.has(141), "Should have ResetSeqNumFlag")
    assert_true(msg.has(93), "Should have field 93")

    # Verify conversions
    assert_equal(msg.get(54).value(), "1", "Int should be '1'")
    assert_equal(msg.get(38).value(), "100", "Int should be '100'")
    assert_equal(msg.get(44).value(), "150.5", "Float should be '150.5'")
    assert_equal(msg.get(141).value(), "Y", "Bool should be 'Y'")
    assert_equal(msg.get(93).value(), "N", "Bool should be 'N'")

    print("  ✅ All type overloads work correctly")


fn assert_true(condition: Bool, message: String) raises:
    if not condition:
        raise Error("Assertion failed: " + message)


fn assert_false(condition: Bool, message: String) raises:
    if condition:
        raise Error("Assertion failed: " + message)


fn assert_equal(a: String, b: String, message: String) raises:
    if a != b:
        raise Error(
            "Assertion failed: "
            + message
            + " (got '"
            + a
            + "', expected '"
            + b
            + "')"
        )


fn main() raises:
    print("=" * 60)
    print("BOOL OVERLOAD AND HAS() METHOD TEST SUITE")
    print("=" * 60)

    test_bool_overload()
    test_has_method()
    test_has_with_conditional()
    test_bool_and_has_combined()
    test_all_type_overloads()

    print("\n" + "=" * 60)
    print("✅ ALL TESTS PASSED!")
    print("=" * 60)
    print("\nBool overload and has() method work correctly.")
    print("All type conversions (String, Int, Float64, Bool) validated.")
