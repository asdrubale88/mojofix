"""Basic usage example for Mojofix.

This example demonstrates:
- Creating a FIX message
- Adding fields
- Encoding the message
"""

from mojofix import FixMessage


fn main() raises:
    print("=" * 60)
    print("Mojofix Basic Usage Example")
    print("=" * 60)

    # Create a new FIX message
    var msg = FixMessage()

    # Add standard header fields
    msg.append_pair(8, "FIX.4.2")  # BeginString
    msg.append_pair(35, "D")  # MsgType: New Order Single

    # Add order details
    msg.append_pair(55, "AAPL")  # Symbol
    msg.append_pair(54, "1")  # Side: Buy
    msg.append_pair(38, "100")  # OrderQty
    msg.append_pair(44, "150.50")  # Price
    msg.append_pair(40, "2")  # OrdType: Limit

    # Encode the message
    var encoded = msg.encode()

    print("\nEncoded FIX Message:")
    print(encoded)

    # Display message statistics
    print("\nMessage Statistics:")
    print("  Field count:", msg.count_fields())
    print("  Has Symbol field:", msg.has_field(55))

    # Access specific fields
    var symbol = msg.get(55)
    if symbol:
        print("  Symbol:", symbol.value())

    var qty = msg.get(38)
    if qty:
        print("  Quantity:", qty.value())

    print("\n" + "=" * 60)
    print("✅ Example completed successfully!")
    print("=" * 60)
