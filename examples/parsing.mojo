"""Message parsing example for Mojofix.

This example demonstrates:
- Parsing FIX messages
- Handling multiple messages
- Error handling
"""

from mojofix import FixParser, FixMessage


fn main() raises:
    print("=" * 60)
    print("Mojofix Parsing Example")
    print("=" * 60)

    # Create a parser
    var parser = FixParser()

    # Example FIX message (with SOH represented as \x01)
    var raw_msg = (
        "8=FIX.4.2\x019=40\x0135=D\x0155=AAPL\x0154=1\x0138=100\x0110=000\x01"
    )

    print("\nParsing FIX message...")
    print("Raw:", repr(raw_msg))

    # Append data to parser buffer
    parser.append_buffer(raw_msg)

    # Extract message
    var msg = parser.get_message()

    if msg:
        print("\n✅ Message parsed successfully!")
        var parsed = msg.value()

        # Display parsed fields
        print("\nParsed Fields:")
        var begin_string = parsed.get(8)
        if begin_string:
            print("  BeginString (8):", begin_string.value())

        var msg_type = parsed.get(35)
        if msg_type:
            print("  MsgType (35):", msg_type.value())

        var symbol = parsed.get(55)
        if symbol:
            print("  Symbol (55):", symbol.value())

        var side = parsed.get(54)
        if side:
            print("  Side (54):", side.value())

        var qty = parsed.get(38)
        if qty:
            print("  OrderQty (38):", qty.value())

        # Validate message
        if parsed.validate():
            print("\n✅ Message is valid")
        else:
            print("\n⚠️ Message validation failed")
    else:
        print("\n❌ Failed to parse message")

    print("\n" + "=" * 60)
    print("✅ Example completed successfully!")
    print("=" * 60)
