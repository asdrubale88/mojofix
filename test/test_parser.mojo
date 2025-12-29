from testing import assert_equal, assert_true
from mojofix.message import FixMessage, SOH
from mojofix.parser import FixParser


fn test_parser() raises:
    print("Testing parser...")
    var parser = FixParser()

    # Valid message: 8=FIX.4.2|9=5|35=A|10=161|
    # Checksum previously calculated as 105 ?
    # Let's construct a known good message using FixMessage
    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "A")
    var encoded = msg.encode()
    print("Generated test message:", encoded)

    # Split into chunks to test buffering
    # encoded[:10] returns StringSlice, must convert to String
    var part1 = String(encoded[:10])
    var part2 = String(encoded[10:])

    parser.append_buffer(part1)
    var res1 = parser.get_message()

    var has_msg = False
    if res1:
        has_msg = True
        _ = res1.take()
    assert_equal(has_msg, False)

    parser.append_buffer(part2)
    var res2 = parser.get_message()

    if res2:
        var m = res2.take()
        assert_equal(m.get(35).value(), "A")
        assert_equal(m.get(8).value(), "FIX.4.2")
    else:
        print("Failed to parse valid message")
        assert_true(False, "Parser returned None")


fn main() raises:
    test_parser()
