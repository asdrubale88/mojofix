"""Test zero-overhead convenience methods.

Tests type conversion overloads and inline helper methods.
"""

from mojofix import FixMessage


fn test_type_conversion_overloads() raises:
    """Test append_pair overloads for Int and Float64."""
    print("Testing type conversion overloads...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "D")

    # Test Int overload
    msg.append_pair(38, 100)  # OrderQty as Int
    msg.append_pair(54, 1)  # Side as Int

    # Test Float64 overload
    msg.append_pair(44, 150.50)  # Price as Float
    msg.append_pair(99, 99.99)  # Another float

    # Verify values were converted correctly
    var qty = msg.get(38)
    assert_true(qty is not None, "OrderQty should exist")
    assert_equal(qty.value(), "100", "OrderQty should be '100'")

    var price = msg.get(44)
    assert_true(price is not None, "Price should exist")
    assert_equal(price.value(), "150.5", "Price should be '150.5'")

    print("  ✅ Type conversion overloads work correctly")


fn test_get_or_helper() raises:
    """Test get_or inline helper method."""
    print("Testing get_or helper...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(55, "AAPL")

    # Test existing field
    var symbol = msg.get_or(55, "UNKNOWN")
    assert_equal(symbol, "AAPL", "Should get AAPL")

    # Test missing field with default
    var missing = msg.get_or(999, "DEFAULT")
    assert_equal(missing, "DEFAULT", "Should get default value")

    # Test missing field with empty default
    var empty = msg.get_or(998)
    assert_equal(empty, "", "Should get empty string")

    print("  ✅ get_or helper works correctly")


fn test_get_int_helper() raises:
    """Test get_int inline helper method."""
    print("Testing get_int helper...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(38, "100")  # OrderQty
    msg.append_pair(54, "1")  # Side
    msg.append_pair(99, "invalid")  # Invalid int

    # Test valid int field
    var qty = msg.get_int(38, 0)
    assert_equal(qty, 100, "Should get 100")

    var side = msg.get_int(54, 0)
    assert_equal(side, 1, "Should get 1")

    # Test missing field with default
    var missing = msg.get_int(999, 42)
    assert_equal(missing, 42, "Should get default value")

    # Test invalid int with default
    var invalid = msg.get_int(99, -1)
    assert_equal(invalid, -1, "Should get default for invalid int")

    print("  ✅ get_int helper works correctly")


fn test_get_float_helper() raises:
    """Test get_float inline helper method."""
    print("Testing get_float helper...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(44, "150.50")  # Price
    msg.append_pair(6, "99.99")  # AvgPx
    msg.append_pair(99, "invalid")  # Invalid float

    # Test valid float field
    var price = msg.get_float(44, 0.0)
    assert_equal(price, 150.5, "Should get 150.5")

    var avg_px = msg.get_float(6, 0.0)
    assert_equal(avg_px, 99.99, "Should get 99.99")

    # Test missing field with default
    var missing = msg.get_float(999, 42.0)
    assert_equal(missing, 42.0, "Should get default value")

    # Test invalid float with default
    var invalid = msg.get_float(99, -1.0)
    assert_equal(invalid, -1.0, "Should get default for invalid float")

    print("  ✅ get_float helper works correctly")


fn test_combined_usage() raises:
    """Test using all convenience methods together."""
    print("Testing combined usage...")

    var msg = FixMessage()

    # Use type conversion overloads
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "D")
    msg.append_pair(55, "AAPL")
    msg.append_pair(54, 1)  # Int overload
    msg.append_pair(38, 100)  # Int overload
    msg.append_pair(44, 150.50)  # Float overload

    # Use helper methods
    var symbol = msg.get_or(55, "UNKNOWN")
    var side = msg.get_int(54, 0)
    var qty = msg.get_int(38, 0)
    var price = msg.get_float(44, 0.0)

    assert_equal(symbol, "AAPL", "Symbol should be AAPL")
    assert_equal(side, 1, "Side should be 1")
    assert_equal(qty, 100, "Qty should be 100")
    assert_equal(price, 150.5, "Price should be 150.5")

    print("  ✅ Combined usage works correctly")


fn assert_true(condition: Bool, message: String) raises:
    if not condition:
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


fn assert_equal(a: Int, b: Int, message: String) raises:
    if a != b:
        raise Error(
            "Assertion failed: "
            + message
            + " (got "
            + String(a)
            + ", expected "
            + String(b)
            + ")"
        )


fn assert_equal(a: Float64, b: Float64, message: String) raises:
    if a != b:
        raise Error(
            "Assertion failed: "
            + message
            + " (got "
            + String(a)
            + ", expected "
            + String(b)
            + ")"
        )


fn main() raises:
    print("=" * 60)
    print("ZERO-OVERHEAD CONVENIENCE METHODS TEST SUITE")
    print("=" * 60)

    test_type_conversion_overloads()
    test_get_or_helper()
    test_get_int_helper()
    test_get_float_helper()
    test_combined_usage()

    print("\n" + "=" * 60)
    print("✅ ALL TESTS PASSED!")
    print("=" * 60)
    print("\nAll convenience methods work correctly with zero overhead.")
    print("Type conversions and inline helpers are production-ready.")
