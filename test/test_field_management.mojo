"""Test field management methods."""

from testing import assert_equal, assert_true, assert_false
from mojofix.message import FixMessage


fn test_getitem_syntax() raises:
    print("Testing __getitem__ syntax...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "D")
    msg.append_pair(55, "AAPL")

    # Test syntactic sugar
    var symbol = msg[55]
    if symbol:
        assert_equal(symbol.value(), "AAPL")
        print("✓ msg[55] returns correct value")
    else:
        raise Error("Symbol should exist")

    # Test non-existent field
    var missing = msg[999]
    if not missing:
        print("✓ msg[999] correctly returns None")
    else:
        raise Error("Field 999 should not exist")

    print("✓ __getitem__ test passed")


fn test_setitem_update() raises:
    print("Testing __setitem__ for updating...")

    var msg = FixMessage()
    msg.append_pair(55, "AAPL")
    msg.append_pair(54, "1")

    # Update existing field using direct method call (workaround for Mojo syntax issue)
    msg.__setitem__(55, "MSFT")

    var updated = msg[55]
    if updated:
        assert_equal(updated.value(), "MSFT")
        print("✓ __setitem__(55, 'MSFT') updated existing field")
    else:
        raise Error("Symbol should exist")

    print("✓ __setitem__ update test passed")


fn test_setitem_append() raises:
    print("Testing __setitem__ for appending...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")

    # Set non-existent field (should append)
    msg.__setitem__(55, "GOOGL")

    var symbol = msg[55]
    if symbol:
        assert_equal(symbol.value(), "GOOGL")
        print("✓ __setitem__(55, 'GOOGL') appended new field")
    else:
        raise Error("Symbol should exist")

    print("✓ __setitem__ append test passed")


fn test_remove_single() raises:
    print("Testing remove() for single field...")

    var msg = FixMessage()
    msg.append_pair(55, "AAPL")
    msg.append_pair(54, "1")
    msg.append_pair(38, "100")

    # Remove field
    var removed = msg.remove(54)
    assert_true(removed, "Should successfully remove field")

    # Verify it's gone
    var side = msg[54]
    if not side:
        print("✓ Field 54 successfully removed")
    else:
        raise Error("Field 54 should be removed")

    # Verify other fields still exist
    if msg[55]:
        print("✓ Other fields still present")

    print("✓ remove() single field test passed")


fn test_remove_repeating() raises:
    print("Testing remove() for repeating groups...")

    var msg = FixMessage()
    msg.append_pair(447, "D")  # First
    msg.append_pair(447, "P")  # Second
    msg.append_pair(447, "C")  # Third

    # Remove second occurrence
    var removed = msg.remove(447, 2)
    assert_true(removed, "Should remove second occurrence")

    # Verify first still exists
    var first = msg.get(447, 1)
    if first:
        assert_equal(first.value(), "D")
        print("✓ First occurrence still present")

    # Verify what was third is now second
    var new_second = msg.get(447, 2)
    if new_second:
        assert_equal(new_second.value(), "C")
        print("✓ Third became second after removal")

    print("✓ remove() repeating groups test passed")


fn test_remove_nonexistent() raises:
    print("Testing remove() for non-existent field...")

    var msg = FixMessage()
    msg.append_pair(55, "AAPL")

    # Try to remove non-existent field
    var removed = msg.remove(999)
    assert_false(removed, "Should return False for non-existent field")

    print("✓ remove() non-existent field test passed")


fn main() raises:
    print("=" * 60)
    print("FIELD MANAGEMENT TESTS")
    print("=" * 60)
    print("Note: Using __setitem__() method directly due to Mojo syntax")
    print()

    test_getitem_syntax()
    test_setitem_update()
    test_setitem_append()
    test_remove_single()
    test_remove_repeating()
    test_remove_nonexistent()

    print("\n" + "=" * 60)
    print("✅ All field management tests passed!")
    print("=" * 60)
