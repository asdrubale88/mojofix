"""HFT module for mojofix - Fast FIX parsing with owned types.

⚠️ ⚠️ ⚠️ EXPERIMENTAL MODULE ⚠️ ⚠️ ⚠️

This module provides fast FIX parsing optimized for high-frequency trading.
It uses owned types (List, String) for safety and compatibility with Mojo 0.26+.

PERFORMANCE CHARACTERISTICS:
- Expected: 2-3x faster than safe FixMessage implementation
- Trade-off: Uses allocations instead of zero-copy for Mojo API compatibility
- Future: Will be optimized to zero-copy once Mojo memory APIs stabilize

WHEN TO USE:
- High-frequency trading applications
- Latency-sensitive systems
- Throughput > 500K msg/sec required

WHEN NOT TO USE:
- General FIX applications (use mojofix.FixMessage instead)
- When maximum safety is more important than speed

Example usage:
```mojo
from mojofix.experimental.hft import FastParser, FastMessage

# Create parser
var parser = FastParser()

# Parse message
var msg = parser.parse("8=FIX.4.2\\x019=40\\x0135=D\\x0155=AAPL\\x01")

# Access fields
var symbol = msg.get(55)  # Tag 55 = Symbol
print(symbol)  # Prints: AAPL

# Reuse parser for next message
var msg2 = parser.parse("8=FIX.4.2\\x019=40\\x0135=D\\x0155=MSFT\\x01")
```
"""

from mojofix.experimental.hft.fast_message import FastMessage, FieldRef
from mojofix.experimental.hft.fast_parser import FastParser
from mojofix.experimental.hft.fast_builder import FastBuilder
from mojofix.experimental.hft.market_data_parser import (
    MarketDataParser,
    MarketDataMessage,
)
