"""SimpleFIX-style API usage example.

Demonstrates mojofix API that closely mirrors Python's simplefix library.
"""

from mojofix import FixMessage, FixParser


fn main() raises:
    print("=" * 60)
    print("SimpleFIX-Compatible API Example")
    print("=" * 60)

    # Creating messages (simplefix-style)
    print("\n1. Creating a FIX message (simplefix-style)")
    print("-" * 60)

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")  # BeginString
    msg.append_pair(35, "D")  # MsgType: New Order
    msg.append_pair(49, "SENDER")  # SenderCompID
    msg.append_pair(56, "TARGET")  # TargetCompID
    msg.append_time(52, 1704067200.0)  # SendingTime
    msg.append_pair(34, "1", header=True)  # MsgSeqNum

    # Add order details
    msg.append_pair(11, "ORDER123")  # ClOrdID
    msg.append_pair(55, "AAPL")  # Symbol
    msg.append_pair(54, "1")  # Side: Buy
    msg.append_pair(38, "100")  # OrderQty
    msg.append_pair(44, "150.50")  # Price
    msg.append_pair(40, "2")  # OrdType: Limit

    print("Message created with", msg.count(), "fields")

    # Encode the message
    print("\n2. Encoding the message")
    print("-" * 60)
    var encoded = msg.encode()
    print("Encoded FIX message:")
    print(encoded)

    # Parsing messages (simplefix-style)
    print("\n3. Parsing the message")
    print("-" * 60)

    var parser = FixParser()
    parser.append_buffer(encoded)

    var parsed_opt = parser.get_message()
    if parsed_opt:
        var parsed = parsed_opt.take()
        print("Successfully parsed message")
        print("Total fields:", parsed.count())

        # Access fields
        print("\n4. Accessing fields")
        print("-" * 60)

        var begin_string = parsed.get(8)
        if begin_string:
            print("BeginString (8):", begin_string.value())

        var msg_type = parsed.get(35)
        if msg_type:
            print("MsgType (35):", msg_type.value())

        var symbol = parsed.get(55)
        if symbol:
            print("Symbol (55):", symbol.value())

        var qty = parsed.get(38)
        if qty:
            print("OrderQty (38):", qty.value())

        var price = parsed.get(44)
        if price:
            print("Price (44):", price.value())

    # Demonstrate timestamp methods
    print("\n5. Timestamp methods (simplefix-compatible)")
    print("-" * 60)

    var msg2 = FixMessage()
    msg2.append_pair(8, "FIX.4.2")
    msg2.append_pair(35, "0")  # Heartbeat
    msg2.append_time(52, 1704067200.0)  # Specific timestamp
    msg2.append_time(60, 1704067200.0)  # Another timestamp
    msg2.append_time(122, 1704067200.0, precision=6)  # Microsecond precision

    print("Created heartbeat with timestamps")
    print("Field count:", msg2.count())

    print("\n" + "=" * 60)
    print("✅ SimpleFIX-compatible API demonstration complete!")
    print("=" * 60)
    print("\nKey simplefix-compatible methods:")
    print("  • append_pair(tag, value, header=False)")
    print("  • append_time(tag, timestamp, precision=3)")
    print("  • append_string(s, header=False)")
    print("  • append_data(len_tag, val_tag, data)")
    print("  • get(tag, nth=1)")
    print("  • count()")
    print("  • encode()")
