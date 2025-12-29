"""Test advanced field operations and message utilities."""

from testing import assert_equal, assert_true, assert_false
from mojofix.message import FixMessage


fn test_clear() raises:
    print("Testing clear()...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "D")
    msg.append_pair(55, "AAPL")

    assert_equal(msg.count_fields(), 3)

    msg.clear()
    assert_equal(msg.count_fields(), 0)
    print("✓ clear() removes all fields")


fn test_count_fields() raises:
    print("Testing count_fields()...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2", header=True)
    msg.append_pair(35, "D", header=True)
    msg.append_pair(55, "AAPL")
    msg.append_pair(54, "1")

    assert_equal(msg.count_fields(), 4)
    print("✓ count_fields() returns correct count")


fn test_has_field() raises:
    print("Testing has_field()...")

    var msg = FixMessage()
    msg.append_pair(55, "MSFT")
    msg.append_pair(54, "2")

    assert_true(msg.has_field(55), "Should have Symbol")
    assert_true(msg.has_field(54), "Should have Side")
    assert_false(msg.has_field(999), "Should not have tag 999")
    print("✓ has_field() works correctly")


fn test_clone() raises:
    print("Testing clone()...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "D")
    msg.append_pair(55, "GOOGL")

    var cloned = msg.clone()

    # Verify clone has same fields
    var symbol = cloned[55]
    if symbol:
        assert_equal(symbol.value(), "GOOGL")
        print("✓ clone() creates copy with same fields")

    # Modify original
    msg.__setitem__(55, "AAPL")

    # Verify clone unchanged
    var cloned_symbol = cloned[55]
    if cloned_symbol:
        assert_equal(cloned_symbol.value(), "GOOGL")
        print("✓ clone() is independent copy")


fn test_reset() raises:
    print("Testing reset()...")

    var msg = FixMessage()
    msg.append_pair(55, "AAPL")
    msg.append_pair(54, "1")

    msg.reset()
    assert_equal(msg.count_fields(), 0)
    print("✓ reset() clears message")


fn test_get_all() raises:
    print("Testing get_all()...")

    var msg = FixMessage()
    msg.append_pair(447, "D")
    msg.append_pair(447, "P")
    msg.append_pair(447, "C")
    msg.append_pair(55, "AAPL")

    var all_447 = msg.get_all(447)
    assert_equal(len(all_447), 3)
    print("✓ get_all() returns all occurrences")


fn test_validate() raises:
    print("Testing validate()...")

    # Valid message
    var valid_msg = FixMessage()
    valid_msg.append_pair(8, "FIX.4.2")
    valid_msg.append_pair(35, "D")
    valid_msg.append_pair(55, "AAPL")

    assert_true(valid_msg.validate(), "Valid message should pass")
    print("✓ validate() accepts valid message")

    # Invalid message (missing required fields)
    var invalid_msg = FixMessage()
    invalid_msg.append_pair(55, "AAPL")

    assert_false(invalid_msg.validate(), "Invalid message should fail")
    print("✓ validate() rejects invalid message")


fn main() raises:
    print("=" * 60)
    print("ADVANCED FIELD OPERATIONS & UTILITIES TESTS")
    print("=" * 60)

    test_clear()
    test_count_fields()
    test_has_field()
    test_clone()
    test_reset()
    test_get_all()
    test_validate()

    print("\n" + "=" * 60)
    print("✅ All advanced operations tests passed!")
    print("=" * 60)
