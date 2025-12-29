# Release v1.0.0 🚀

We are thrilled to announce the first stable release of **Mojofix**, a high-performance Financial Information eXchange (FIX) protocol library for Mojo!

Mojofix is designed to be a drop-in replacement for Python's `simplefix` but with significantly higher performance, leveraging Mojo's system-level capabilities.

## 🌟 Highlights

*   **100% Feature Compatibility**: Fully passes the `simplefix` compatibility test suite (25/25 tests).
*   **High Performance**:
    *   **Safe Parser**: ~600k msg/sec (Comparable to optimized C++ engines).
    *   **HFT Parser (Experimental)**: **>5.7M msg/sec** (9x faster) for ultra-low latency requirements.
*   **Zero Dependencies**: Pure Mojo implementation.
*   **Full Protocol Support**: Handles FIX 4.2, 4.4, 5.0SP2, repeating groups, and binary fields.

## 🚀 Performance Benchmarks

| Message Type | Safe Parser | HFT Parser | Speedup |
| :--- | :--- | :--- | :--- |
| **Short (Heartbeat)** | 612k msg/s | **5.7M msg/s** | **9.3x** |
| **Medium (Order)** | 272k msg/s | **2.0M msg/s** | **7.5x** |
| **Long (Snapshot)** | 36k msg/s | **228k msg/s** | **6.3x** |

## 📦 Installation

```bash
pixi add mojofix
```

## 🛠️ Usage

**Standard Safe Usage:**
```mojo
from mojofix import FixMessage, FixParser

var msg = FixMessage()
msg.append_pair(35, "D")
print(msg.encode())
```

**Experimental HFT Usage (Zero-Copy):**
```mojo
from mojofix.experimental.hft import FastParser, FastMessage

var parser = FastParser()
var msg = FastMessage("")
parser.parse_into(raw_data, msg) # Zero allocations
```

## 🙏 Acknowledgments

Big thanks to the [simplefix](https://github.com/da4089/simplefix) project for the inspiration and robustness standards.
