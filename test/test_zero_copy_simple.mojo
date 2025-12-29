from mojofix.zero_copy import parse_zero_copy
from mojofix.message import FixMessage

fn main() raises:
    print("Testing zero-copy parser...")
    
    # Create simple message
    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "D")
    msg.append_pair(55, "AAPL")
    var encoded = msg.encode()
    
    print("Encoded:", encoded)
    
    # Parse with zero-copy
    var zc_msg = parse_zero_copy(encoded)
    print("Fields parsed:", zc_msg.count_fields())
    
    # Get symbol
    var symbol = zc_msg.get(55)
    if symbol:
        print("Symbol:", symbol.value())
    else:
        print("Symbol not found")
    
    print("✅ Zero-copy parser working!")
