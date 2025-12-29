"""HFT module for mojofix - Zero-copy, arena-based FIX parsing.

⚠️ ⚠️ ⚠️ WARNING: UNSAFE API ⚠️ ⚠️ ⚠️

This module provides ultra-low latency FIX parsing for high-frequency trading.
It achieves 4M+ msg/sec by eliminating heap allocations.

SAFETY REQUIREMENTS:
1. Arena must outlive all MessageView/StringView objects
2. Do not modify arena while views are active
3. No automatic bounds checking - caller responsible
4. Assumes well-formed FIX messages

WHEN TO USE:
- High-frequency trading applications
- Latency-critical systems (< 5 microseconds)
- Throughput > 1M msg/sec required

WHEN NOT TO USE:
- General FIX applications (use mojofix.FixMessage instead)
- When safety is more important than speed
- Untrusted message sources

Example usage:
```mojo
from mojofix.hft import ArenaParser, MessageView

# Create parser with 1MB arena
var parser = ArenaParser()

# Parse message (zero-copy)
var msg = parser.parse_message("8=FIX.4.2\x019=...\x01")

# Access fields (returns StringView, not String)
var symbol = msg.get(55)  # Tag 55 = Symbol
print(symbol)  # Converts to String for display

# Reset arena when done with batch
parser.reset_arena()
```
"""

from mojofix.hft.arena import Arena
from mojofix.hft.string_view import StringView
from mojofix.hft.message_view import MessageView, FieldView
from mojofix.hft.parser_fast import ArenaParser
