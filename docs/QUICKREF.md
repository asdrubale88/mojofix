# SimpleFIX → Mojofix Quick Reference

**One-page guide for Python developers migrating from simplefix to mojofix.**

---

## Identical API ✅

These methods work exactly the same:

```python
# Python (simplefix)          # Mojo (mojofix)
msg.append_pair(55, "AAPL")   var msg.append_pair(55, "AAPL")
msg.append_string("55=AAPL")  msg.append_string("55=AAPL")
msg.count()                   msg.count()
msg.encode()                  msg.encode()
parser.append_buffer(data)    parser.append_buffer(data)
parser.get_message()          parser.get_message()
```

---

## Minor Syntax Differences ⚠️

| Python (simplefix) | Mojo (mojofix) | Why |
|--------------------|----------------|-----|
| `msg = simplefix.FixMessage()` | `var msg = FixMessage()` | Mojo requires `var` keyword |
| `msg.get(55).decode('utf-8')` | `msg.get(55).value()` | Mojo uses String not bytes |
| `msg.append_time(52)` | `msg.append_time(52, timestamp)` | No built-in current time in Mojo |
| `msg.append_pair(38, 100)` | `msg.append_pair(38, 100)` | ✅ **NEW**: Auto-converts Int/Float! |

---

## New Convenience Methods 🎁

**Zero-overhead helpers** (all use `@always_inline` or compile-time overloads):

```mojo
# Get with default (no Optional handling needed)
var symbol = msg.get_or(55, "UNKNOWN")

# Get as Int (auto-converts)
var qty = msg.get_int(38, 0)

# Get as Float (auto-converts)  
var price = msg.get_float(44, 0.0)

# Check field existence (cleaner than Optional check)
if msg.has(55):
    print(msg.get(55).value())

# Type conversion overloads
msg.append_pair(38, 100)      # Int - auto-converts
msg.append_pair(44, 150.50)   # Float - auto-converts
msg.append_pair(141, True)    # Bool - auto-converts to Y/N!
```

---

## Common Patterns

### Creating Messages

**Python (simplefix):**
```python
import simplefix

msg = simplefix.FixMessage()
msg.append_pair(8, "FIX.4.2")
msg.append_pair(35, "D")
msg.append_pair(55, "AAPL")
msg.append_pair(54, 1)        # Side: Buy
msg.append_pair(38, 100)      # Quantity
msg.append_pair(44, 150.50)   # Price
```

**Mojo (mojofix):**
```mojo
from mojofix import FixMessage

var msg = FixMessage()
msg.append_pair(8, "FIX.4.2")
msg.append_pair(35, "D")
msg.append_pair(55, "AAPL")
msg.append_pair(54, 1)        # ✅ Auto-converts Int!
msg.append_pair(38, 100)      # ✅ Auto-converts Int!
msg.append_pair(44, 150.50)   # ✅ Auto-converts Float!
```

### Parsing Messages

**Python (simplefix):**
```python
parser = simplefix.FixParser()
parser.append_buffer(data)
msg = parser.get_message()

if msg:
    symbol = msg.get(55).decode('utf-8')
    qty = int(msg.get(38).decode('utf-8'))
    price = float(msg.get(44).decode('utf-8'))
```

**Mojo (mojofix) - Traditional:**
```mojo
var parser = FixParser()
parser.append_buffer(data)
var msg_opt = parser.get_message()

if msg_opt:
    var msg = msg_opt.take()
    var symbol_opt = msg.get(55)
    if symbol_opt:
        var symbol = symbol_opt.value()
    # ... verbose Optional handling
```

**Mojo (mojofix) - With Helpers:**
```mojo
var parser = FixParser()
parser.append_buffer(data)
var msg_opt = parser.get_message()

if msg_opt:
    var msg = msg_opt.take()
    var symbol = msg.get_or(55, "UNKNOWN")  # ✅ Simpler!
    var qty = msg.get_int(38, 0)            # ✅ Auto-converts!
    var price = msg.get_float(44, 0.0)      # ✅ Auto-converts!
```

---

## Timestamp Handling

**Python (simplefix):**
```python
import time
msg.append_time(52)                    # Current time
msg.append_time(60, time.time())       # Specific time
```

**Mojo (mojofix):**
```mojo
# Option 1: Pass timestamp explicitly
msg.append_time(52, 1704067200.0)

# Option 2: Use from calling context
fn process_order(timestamp: Float64):
    var msg = FixMessage()
    msg.append_time(52, timestamp)
```

> **Note**: Mojo doesn't have built-in current time. Pass timestamps from your application context.

---

## Performance Tips 🚀

### Use HFT API for Parsing (5-9x faster)

```mojo
from mojofix.experimental.hft import FastParser

var parser = FastParser()
var msg = parser.parse(raw_data)  # Zero-copy!
var symbol = msg.get(55)           # Direct access
```

### Use HFT API for Building (with Buffer Reuse)

```mojo
from mojofix.experimental.hft import FastBuilder

var builder = FastBuilder()

// Build first message
builder.append_pair(8, "FIX.4.2")
builder.append_pair(35, "D")
builder.append_pair(55, "AAPL")
var msg1 = builder.encode()

// Reuse for next message (zero allocation!)
builder.reset()
builder.append_pair(8, "FIX.4.2")
builder.append_pair(35, "D")
builder.append_pair(55, "MSFT")
var msg2 = builder.encode()
```

> **Note**: FastBuilder provides simplefix-compatible API with buffer reuse. Currently runs at ~66% of safe builder speed but offers zero-allocation message building via `reset()`.

### Reuse Objects in Hot Loops

```mojo
var msg = FixMessage()
for order in orders:
    msg.clear()  # Reuse instead of allocating
    msg.append_pair(55, order.symbol)
    # ... build message
```

### Batch Operations

```mojo
# Instead of multiple append_pair calls:
var tags = List[Int](55, 54, 38)
var values = List[String]("AAPL", "1", "100")
msg.append_pairs(tags, values)  # More efficient
```

---

## Migration Checklist ✓

- [ ] Replace `import simplefix` with `from mojofix import FixMessage, FixParser`
- [ ] Add `var` keyword to variable declarations
- [ ] Replace `.decode('utf-8')` with `.value()` or use `get_or()`
- [ ] Pass explicit timestamps to `append_time()`
- [ ] Use `get_int()` / `get_float()` for numeric fields (optional but convenient)
- [ ] Test with your existing FIX messages
- [ ] Consider HFT FastParser for performance-critical parsing
- [ ] Consider HFT FastBuilder for high-frequency message building with buffer reuse

---

## API Compatibility Matrix

| Feature | simplefix | mojofix | Compatible |
|---------|-----------|---------|------------|
| Message creation | ✅ | ✅ | ✅ 100% |
| Field append | ✅ | ✅ | ✅ 100% + auto-conversion |
| Field access | ✅ | ✅ | ✅ 100% + helpers |
| Parsing | ✅ | ✅ | ✅ 100% |
| Encoding | ✅ | ✅ | ✅ 100% |
| Timestamps | ✅ | ⚠️ | ⚠️ Requires explicit timestamp |
| Data fields | ✅ | ✅ | ✅ 100% |
| Repeating groups | ✅ | ✅ | ✅ 100% |

---

## Performance Comparison

| Operation | simplefix (Python) | mojofix (Safe) | mojofix (HFT) |
|-----------|-------------------|----------------|---------------|
| Parse short msg | ~10 μs | ~1.6 μs | **~0.17 μs** (FastParser) |
| Parse medium msg | ~15 μs | ~3.7 μs | **~0.5 μs** (FastParser) |
| Build & encode | ~12 μs | ~1.8 μs | ~2.8 μs (FastBuilder reuse) |
| **Parse Speedup** | 1x | **6-8x** | **50-60x** |
| **Build Speedup** | 1x | **6-7x** | **4-5x** (with reuse) |

---

## Need Help?

- **Examples**: See [examples/simplefix_style.mojo](file:///home/matteo/mojofix/examples/simplefix_style.mojo)
- **Migration Guide**: See [docs/simplefix_migration.md](file:///home/matteo/mojofix/docs/simplefix_migration.md)
- **API Docs**: See [README.md](file:///home/matteo/mojofix/README.md)
- **Issues**: Report on GitHub

---

**TL;DR**: Add `var`, use `.value()` or helper methods, pass timestamps explicitly. Everything else works the same but **6-60x faster**! 🚀
