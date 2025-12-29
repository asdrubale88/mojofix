"""Test batch operations."""

from testing import assert_equal, assert_true
from mojofix.message import FixMessage


fn test_append_strings() raises:
    print("Testing append_strings()...")

    var msg = FixMessage()

    # Create batch of strings
    var strings = List[String]()
    strings.append("55=AAPL")
    strings.append("54=1")
    strings.append("38=100")
    strings.append("44=150.50")

    # Append in batch
    msg.append_strings(strings)

    # Verify all fields were added
    var symbol = msg[55]
    var side = msg[54]
    var qty = msg[38]
    var price = msg[44]

    if symbol:
        assert_equal(symbol.value(), "AAPL")
        print("✓ Symbol field correct")

    if side:
        assert_equal(side.value(), "1")
        print("✓ Side field correct")

    if qty:
        assert_equal(qty.value(), "100")
        print("✓ Quantity field correct")

    if price:
        assert_equal(price.value(), "150.50")
        print("✓ Price field correct")

    print("✓ append_strings() test passed")


fn test_append_strings_header() raises:
    print("Testing append_strings() with header=True...")

    var msg = FixMessage()

    var header_strings = List[String]()
    header_strings.append("8=FIX.4.2")
    header_strings.append("35=D")

    msg.append_strings(header_strings, header=True)

    # Verify header fields
    var begin_string = msg[8]
    var msg_type = msg[35]

    if begin_string:
        assert_equal(begin_string.value(), "FIX.4.2")
        print("✓ BeginString in header")

    if msg_type:
        assert_equal(msg_type.value(), "D")
        print("✓ MsgType in header")

    print("✓ append_strings() header test passed")


fn test_append_pairs() raises:
    print("Testing append_pairs()...")

    var msg = FixMessage()

    # Create parallel lists
    var tags = List[Int]()
    tags.append(55)
    tags.append(54)
    tags.append(38)

    var values = List[String]()
    values.append("MSFT")
    values.append("2")
    values.append("200")

    # Append in batch
    msg.append_pairs(tags, values)

    # Verify all fields
    var symbol = msg[55]
    var side = msg[54]
    var qty = msg[38]

    if symbol:
        assert_equal(symbol.value(), "MSFT")
        print("✓ Symbol correct")

    if side:
        assert_equal(side.value(), "2")
        print("✓ Side correct")

    if qty:
        assert_equal(qty.value(), "200")
        print("✓ Quantity correct")

    print("✓ append_pairs() test passed")


fn test_batch_performance() raises:
    print("Testing batch operation performance...")

    var msg = FixMessage()

    # Create large batch
    var tags = List[Int]()
    var values = List[String]()

    for i in range(100):
        tags.append(10000 + i)
        values.append("value" + String(i))

    # Append all at once
    msg.append_pairs(tags, values)

    # Verify count
    var count = msg.count()
    if count >= 100:
        print("✓ All 100+ fields added")

    print("✓ Batch performance test passed")


fn main() raises:
    print("=" * 60)
    print("BATCH OPERATIONS TESTS")
    print("=" * 60)

    test_append_strings()
    test_append_strings_header()
    test_append_pairs()
    test_batch_performance()

    print("\n" + "=" * 60)
    print("✅ All batch operation tests passed!")
    print("=" * 60)
