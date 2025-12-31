# Mojofix 🔥

**High-performance FIX protocol library for Mojo** - Achieving >4M msg/sec (4x faster than QuickFIX C++) with 100% feature parity with Python's `simplefix`.

[![Tests](https://img.shields.io/badge/tests-25%2F25%20passing-brightgreen)]()
[![Mojo](https://img.shields.io/badge/mojo-%E2%89%A50.26.1-orange)]()
[![License](https://img.shields.io/badge/license-MIT-blue)]()

## ✨ Features

- **🚀 High Performance**: 5.7M msg/sec (Zero-Copy Parser), ~600k msg/sec (Safe Parser)
- **✅ 100% Compatible**: Drop-in replacement for Python's simplefix
- **🔒 Production Ready**: All 25 simplefix compatibility tests passing
- **⚡ SIMD Optimized**: 4-8x faster checksum calculation (Auto-Vectorized)
- **🎯 Zero Dependencies**: Pure Mojo implementation

## SimpleFIX Compatibility

Mojofix provides a **simplefix-compatible API** for seamless migration from Python:

**Python (simplefix):**
```python
import simplefix
msg = simplefix.FixMessage()
msg.append_pair(55, "AAPL")
msg.append_time(52)
encoded = msg.encode()
```

**Mojo (mojofix):**
```mojo
from mojofix import FixMessage
var msg = FixMessage()
msg.append_pair(55, "AAPL")
msg.append_time(52)
var encoded = msg.encode()
```

**Key compatible methods:**
- `append_pair(tag, value, header=False)` - Add field to message (auto-converts Int/Float64!)
- `append_time(tag, timestamp, precision=3)` - Add UTC timestamp (alias for append_utc_timestamp)
- `append_string(s, header=False)` - Parse and add "tag=value" string
- `append_data(len_tag, val_tag, data)` - Add data field with length prefix
- `get(tag, nth=1)` - Get field value
- `get_or(tag, default="")` - Get field or default (no Optional handling!)
- `get_int(tag, default=0)` - Get field as Int (auto-converts!)
- `get_float(tag, default=0.0)` - Get field as Float64 (auto-converts!)
- `count()` - Get total field count
- `encode()` - Encode message

**New convenience features** (zero overhead with `@always_inline`):
```mojo
msg.append_pair(38, 100)         # Auto-converts Int!
msg.append_pair(44, 150.50)      # Auto-converts Float64!
msg.append_pair(141, True)       # Auto-converts Bool to Y/N!
var symbol = msg.get_or(55, "")  # No Optional handling needed!
var qty = msg.get_int(38, 0)     # Direct Int conversion!
if msg.has(55):                  # Clean existence check!
    print(msg.get(55).value())
```

See the [SimpleFIX Migration Guide](docs/simplefix_migration.md) and [Quick Reference](docs/QUICKREF.md) for complete details.

## 📊 Performance

| Message Type | Safe Parser | HFT Parser | Speedup |
| :--- | :--- | :--- | :--- |
| **Short (Heartbeat)** | 612k msg/s | **5.7M msg/s** | **9.3x** |
| **Medium (Order)** | 272k msg/s | **2.0M msg/s** | **7.5x** |
| **Long (Snapshot)** | 36k msg/s | **228k msg/s** | **6.3x** |

*Benchmarked on single thread with valid FIX messages (4.2, 4.4, 5.0SP2)*

## 🚀 Quick Start

### Installation

```bash
# Using pixi (recommended)
pixi add mojofix

# Or clone and build
git clone https://github.com/asdrubale88/mojofix
cd mojofix
pixi install
```

### Basic Usage

```mojo
from mojofix import FixMessage, FixParser

fn main() raises:
    # Create a FIX message
    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "D")  # New Order Single
    msg.append_pair(55, "AAPL")  # Symbol
    msg.append_pair(54, "1")  # Side: Buy
    msg.append_pair(38, "100")  # Quantity
    
    # Encode to FIX format
    var encoded = msg.encode()
    print(encoded)
    
    # Parse a FIX message
    var parser = FixParser()
    parser.append_buffer(encoded)
    var parsed = parser.get_message()
    
    if parsed:
        var symbol = parsed.value().get(55)
        if symbol:
            print("Symbol:", symbol.value())
```

## 📚 Documentation

- [API Reference](API.md) - Complete API documentation
- [Migration Guide](MIGRATION.md) - Migrating from Python simplefix
- [Examples](examples/) - Code examples
- [Contributing](CONTRIBUTING.md) - Development guide

## 🎯 Feature Parity

### Core FIX Protocol
- ✅ Message creation & encoding
- ✅ Message parsing
- ✅ Raw data fields (binary with embedded SOH)
- ✅ Repeating groups
- ✅ Header/body separation
- ✅ Checksum calculation & validation

### Timestamps (All FIX Formats)
- ✅ UTC timestamps (`UTCTimestamp`)
- ✅ Timezone-aware timestamps (`TZTimestamp`)
- ✅ Date-only (`UTCDateOnly`)
- ✅ Time-only (`UTCTimeOnly`)
- ✅ Month-year (`MonthYear`)
- ✅ Local market date (`LocalMktDate`)

### Field Management
- ✅ Get/set/remove fields
- ✅ Batch operations
- ✅ Field validation
- ✅ Multiple occurrences
- ✅ Clone & reset

## 🧪 Testing

```bash
# Run compatibility test suite
pixi run test

# Run all tests
pixi run mojo -I src test/test_message.mojo
pixi run mojo -I src test/test_parser.mojo
pixi run mojo -I src test/test_data_fields.mojo

# Run benchmarks
pixi run mojo -I src benchmarks/bench_comprehensive.mojo
```

**Test Coverage**: 25/25 simplefix compatibility tests passing ✅

## 🏗️ Project Structure

```
mojofix/
├── src/mojofix/
│   ├── message.mojo          # FixMessage implementation
│   ├── parser.mojo           # FixParser implementation
│   ├── time_utils.mojo       # Timestamp formatting
│   ├── simd_utils.mojo       # SIMD optimizations
│   └── experimental/hft/     # HFT module (FastParser + FastBuilder)
│       ├── fast_parser.mojo  # Zero-copy parser
│       ├── fast_message.mojo # Zero-copy message
│       └── fast_builder.mojo # Fast message builder
├── test/                     # Test suites
├── benchmarks/               # Performance benchmarks
└── examples/                 # Usage examples
```

## 🎯 Use Cases

Perfect for:
- High-frequency trading systems
- Low-latency messaging
- Real-time market data processing
- FIX protocol gateways
- Financial applications requiring high performance

## 🚀 HFT Module (Experimental)

For ultra-low latency applications, `mojofix` provides an experimental HFT module with fast parsing **and building**.

| Feature | Safe (`mojofix`) | HFT (`mojofix.experimental.hft`) |
|---------|------------------|----------------------------------|
| **Parser Speed** | ~600k msg/sec | **~5.7M msg/sec** (9x faster) |
| **Parser Latency** | ~1.60 μs | **~0.17 μs** |
| **Builder Speed** | ~543k msg/sec | ~359k msg/sec (reuse mode) |
| **Memory** | Safe (Heap + Dict) | Manual w/ Indexing |
| **Design** | Allocation per message | Zero-copy + Buffer Reuse |
| **Status** | Production Ready | Experimental |

### Fast Parsing

```mojo
from mojofix.experimental.hft import FastParser, FastMessage

fn main() raises:
    # 1. Reuse message object to avoid allocation overhead
    var parser = FastParser()
    var msg = FastMessage("")
    
    # 2. Parse into existing object (Zero-Allocation path)
    parser.parse_into("8=FIX.4.2\x0135=D\x01...", msg)
    
    # 3. Access fields (lazy string creation)
    print(msg.get(35))
```

### Fast Building

```mojo
from mojofix.experimental.hft import FastBuilder

fn main() raises:
    var builder = FastBuilder()
    
    # Build message with simplefix-compatible API
    builder.append_pair(8, "FIX.4.2")
    builder.append_pair(35, "D")
    builder.append_pair(55, "AAPL")
    builder.append_pair(54, 1)      # Auto-converts Int
    builder.append_pair(38, 100)    # Auto-converts Int
    builder.append_pair(44, 150.50) # Auto-converts Float
    
    var msg = builder.encode()
    
    # Reuse for next message (zero allocation)
    builder.reset()
```

> **Note**: FastBuilder currently performs at 66% of safe builder speed due to Mojo string handling limitations. It's valuable for its simplefix-compatible API and buffer reuse capabilities. Performance will improve significantly when Mojo adds efficient byte-to-string conversion.

## 🚀 Roadmap

- [x] Core FIX protocol implementation
- [x] 100% simplefix compatibility
- [x] SIMD optimizations
- [x] Comprehensive test suite
- [x] HFT zero-copy module (Available in `mojofix.experimental.hft`)
- [ ] Explicit SIMD delimiter scanning (Target: 10M msg/s)
- [ ] Multi-threading support

## 📝 License

MIT License - see [LICENSE](LICENSE) for details

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 🙏 Acknowledgments

Based on the Python [simplefix](https://github.com/da4089/simplefix) library by David Arnold.

---

**Status**: Production-ready v1.0 ✅  
**Performance**: >5M msg/sec (HFT Mode) 🚀
