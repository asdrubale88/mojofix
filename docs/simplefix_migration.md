# SimpleFIX Migration Guide

This guide helps Python developers migrate from `simplefix` to `mojofix`.

## Quick Start

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

## API Compatibility

Mojofix provides a simplefix-compatible API. Most methods work identically.

### Message Creation

| Operation | simplefix (Python) | mojofix (Mojo) | Status |
|-----------|-------------------|----------------|--------|
| Create message | `msg = simplefix.FixMessage()` | `var msg = FixMessage()` | ✅ Compatible |
| Add field | `msg.append_pair(55, "AAPL")` | `msg.append_pair(55, "AAPL")` | ✅ Identical |
| Add string | `msg.append_string("55=AAPL")` | `msg.append_string("55=AAPL")` | ✅ Identical |
| Add timestamp | `msg.append_time(52)` | `msg.append_time(52, timestamp)` | ⚠️ Requires timestamp |
| Add data field | `msg.append_data(95, 96, data)` | `msg.append_data(95, 96, data)` | ✅ Identical |
| Count fields | `msg.count()` | `msg.count()` | ✅ Identical |
| Encode | `msg.encode()` | `msg.encode()` | ✅ Identical |

### Message Parsing

| Operation | simplefix (Python) | mojofix (Mojo) | Status |
|-----------|-------------------|----------------|--------|
| Create parser | `parser = simplefix.FixParser()` | `var parser = FixParser()` | ✅ Compatible |
| Add buffer | `parser.append_buffer(data)` | `parser.append_buffer(data)` | ✅ Identical |
| Get message | `msg = parser.get_message()` | `var msg_opt = parser.get_message()` | ⚠️ Returns Optional |
| Get field | `value = msg.get(55)` | `var value = msg.get(55)` | ⚠️ Returns Optional |
| Get nth field | `value = msg.get(55, 2)` | `var value = msg.get(55, 2)` | ⚠️ Returns Optional |

## Key Differences

### 1. Variable Declarations

**Python:**
```python
msg = simplefix.FixMessage()
value = msg.get(55)
```

**Mojo:**
```mojo
var msg = FixMessage()  # Use 'var' keyword
var value = msg.get(55)
```

### 2. Optional Return Types

**Python:**
```python
value = msg.get(55)
if value:
    print(value.decode('utf-8'))
```

**Mojo:**
```mojo
var value = msg.get(55)  # Returns Optional[String]
if value:
    print(value.value())  # Unwrap with .value()
```

### 3. String vs Bytes

**Python (simplefix):**
- Returns `bytes` objects
- Need to decode: `value.decode('utf-8')`

**Mojo (mojofix):**
- Returns `String` objects directly
- No decoding needed

### 4. Error Handling

**Python:**
```python
try:
    msg.append_pair(55, "AAPL")
except Exception as e:
    print(f"Error: {e}")
```

**Mojo:**
```mojo
fn main() raises:  # Declare function can raise
    var msg = FixMessage()
    msg.append_pair(55, "AAPL")  # Errors propagate automatically
```

### 5. Timestamp Methods

**Python (simplefix):**
```python
msg.append_time(52)  # Defaults to current time
msg.append_time(60, 1704067200.0)  # Specific time
```

**Mojo (mojofix):**
```mojo
msg.append_time(52, 1704067200.0)  # Requires explicit timestamp
msg.append_time(60, 1704067200.0)  # Specific time
```

> **Note**: Unlike Python's simplefix, `append_time()` in mojofix requires an explicit timestamp parameter. Mojo 0.26.1 doesn't provide a built-in way to get current time without Python interop. Use benchmarking utilities or Python interop if you need current time.

## Complete Migration Example

### Before (Python/simplefix)

```python
import simplefix
import time

# Create and populate message
msg = simplefix.FixMessage()
msg.append_pair(8, "FIX.4.2")
msg.append_pair(35, "D")
msg.append_pair(49, "SENDER")
msg.append_pair(56, "TARGET")
msg.append_time(52)
msg.append_pair(34, 1, header=True)

msg.append_pair(11, "ORDER123")
msg.append_pair(55, "AAPL")
msg.append_pair(54, 1)
msg.append_pair(38, 100)

# Encode
encoded = msg.encode()
print(f"Encoded: {encoded.decode('utf-8')}")

# Parse
parser = simplefix.FixParser()
parser.append_buffer(encoded)
parsed = parser.get_message()

if parsed:
    symbol = parsed.get(55)
    if symbol:
        print(f"Symbol: {symbol.decode('utf-8')}")
    
    print(f"Field count: {parsed.count()}")
```

### After (Mojo/mojofix)

```mojo
from mojofix import FixMessage, FixParser

fn main() raises:
    # Create and populate message
    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "D")
    msg.append_pair(49, "SENDER")
    msg.append_pair(56, "TARGET")
    msg.append_time(52, 1704067200.0)
    msg.append_pair(34, "1", header=True)
    
    msg.append_pair(11, "ORDER123")
    msg.append_pair(55, "AAPL")
    msg.append_pair(54, "1")
    msg.append_pair(38, "100")
    
    # Encode
    var encoded = msg.encode()
    print("Encoded:", encoded)
    
    # Parse
    var parser = FixParser()
    parser.append_buffer(encoded)
    var parsed_opt = parser.get_message()
    
    if parsed_opt:
        var parsed = parsed_opt.take()
        var symbol = parsed.get(55)
        if symbol:
            print("Symbol:", symbol.value())
        
        print("Field count:", parsed.count())
```

## Performance Benefits

Mojofix provides the same API as simplefix but with significant performance improvements:

- **10-100x faster** message creation and parsing
- **Zero-copy parsing** available via HFT API
- **Native performance** - compiled to machine code
- **SIMD optimizations** for checksums and scanning

## HFT API (Advanced)

For maximum performance, mojofix offers an experimental HFT API:

```mojo
from mojofix.experimental.hft import FastParser

fn main() raises:
    var parser = FastParser()
    var data = "8=FIX.4.2\x0135=D\x0155=AAPL\x01..."
    
    var msg = parser.parse(data)
    var symbol = msg.get(55)  # Zero-copy access
    print("Symbol:", symbol)
    print("Field count:", msg.count())
```

The HFT API provides:
- Zero-copy field access
- 2-5x faster than memory-safe API
- Read-only message access

## Migration Checklist

- [ ] Replace `import simplefix` with `from mojofix import FixMessage, FixParser`
- [ ] Add `var` keyword to variable declarations
- [ ] Add `fn main() raises:` wrapper
- [ ] Handle `Optional` return types with `.value()`
- [ ] Remove `.decode('utf-8')` calls (strings are native)
- [ ] Convert numeric values to strings when needed
- [ ] Test with your existing FIX messages

## Need Help?

- See [examples/simplefix_style.mojo](../examples/simplefix_style.mojo) for working code
- Check the [API documentation](../README.md) for full method reference
- Report issues on GitHub
