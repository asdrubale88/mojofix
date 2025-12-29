from testing import assert_equal
from mojofix.message import FixMessage


fn test_repeating_groups() raises:
    print("Testing repeating groups support...")
    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "D")

    # Add multiple occurrences of tag 447 (PartyIDSource)
    msg.append_pair(447, "D")  # First occurrence
    msg.append_pair(448, "PARTY1")
    msg.append_pair(447, "P")  # Second occurrence
    msg.append_pair(448, "PARTY2")
    msg.append_pair(447, "C")  # Third occurrence
    msg.append_pair(448, "PARTY3")

    # Test getting different occurrences
    var first = msg.get(447, 1)
    if first:
        assert_equal(first.value(), "D")
        print("✓ First occurrence: D")
    else:
        raise Error("First occurrence should exist")

    var second = msg.get(447, 2)
    if second:
        assert_equal(second.value(), "P")
        print("✓ Second occurrence: P")
    else:
        raise Error("Second occurrence should exist")

    var third = msg.get(447, 3)
    if third:
        assert_equal(third.value(), "C")
        print("✓ Third occurrence: C")
    else:
        raise Error("Third occurrence should exist")

    # Test non-existent occurrence
    var fourth = msg.get(447, 4)
    if fourth:
        raise Error("Fourth occurrence should not exist")
    else:
        print("✓ Fourth occurrence correctly returns None")

    print("✓ All repeating groups tests passed")


fn test_default_nth_parameter() raises:
    print("Testing default nth=1 parameter...")
    var msg = FixMessage()
    msg.append_pair(55, "AAPL")
    msg.append_pair(55, "MSFT")

    # Default should return first occurrence
    var symbol = msg.get(55)  # nth defaults to 1
    if symbol:
        assert_equal(symbol.value(), "AAPL")
        print("✓ Default nth=1 returns first occurrence")
    else:
        raise Error("Symbol should exist")


fn main() raises:
    test_repeating_groups()
    test_default_nth_parameter()
    print("\nAll repeating groups tests passed!")
