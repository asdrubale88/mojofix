# Mojofix v1.0 - API Reference

Complete API documentation for mojofix FIX protocol library.

## FixMessage

Main class for creating and manipulating FIX messages.

### Creation

```mojo
var msg = FixMessage()
```

### Field Operations

#### append_pair(tag: Int, value: String, header: Bool = False)
Add a tag-value pair to the message.

```mojo
msg.append_pair(55, "AAPL")
msg.append_pair(8, "FIX.4.2", header=True)
```

#### append_string(s: String, header: Bool = False)
Add a field from "tag=value" string.

```mojo
msg.append_string("55=AAPL")
```

#### append_strings(strings: List[String], header: Bool = False)
Bulk append multiple tag=value strings.

```mojo
var strings = List[String]()
strings.append("55=AAPL")
strings.append("54=1")
msg.append_strings(strings)
```

#### append_pairs(tags: List[Int], values: List[String], header: Bool = False)
Bulk append tag-value pairs.

```mojo
var tags = List[Int]()
var values = List[String]()
tags.append(55)
values.append("AAPL")
msg.append_pairs(tags, values)
```

#### append_data(len_tag: Int, val_tag: Int, data: String, header: Bool = False)
Append raw data field with length prefix.

```mojo
msg.append_data(91, 90, binary_data)  # SecDataLen/SecData
```

### Timestamp Methods

#### append_utc_timestamp(tag: Int, timestamp: Float64, precision: Int = 3, header: Bool = False)
Append UTC timestamp (YYYYMMDD-HH:MM:SS[.sss]).

```mojo
msg.append_utc_timestamp(52, 1705318245.123)
```

#### append_tz_timestamp(tag: Int, timestamp: Float64, offset_minutes: Int, precision: Int = 3, header: Bool = False)
Append timezone-aware timestamp.

```mojo
msg.append_tz_timestamp(52, timestamp, -300)  # EST
```

#### append_utc_date_only(tag: Int, timestamp: Float64, header: Bool = False)
Append date-only field (YYYYMMDD).

```mojo
msg.append_utc_date_only(75, timestamp)  # TradeDate
```

#### append_time_only(tag: Int, timestamp: Float64, precision: Int = 3, header: Bool = False)
Append time-only field (HH:MM:SS[.sss]).

```mojo
msg.append_time_only(108, timestamp)
```

#### append_local_mkt_date(tag: Int, timestamp: Float64, header: Bool = False)
Append LocalMktDate field (YYYYMMDD).

```mojo
msg.append_local_mkt_date(1300, timestamp)
```

#### append_month_year(tag: Int, timestamp: Float64, header: Bool = False)
Append MonthYear field (YYYYMM).

```mojo
msg.append_month_year(200, timestamp)
```

### Field Access

#### get(tag: Int, nth: Int = 1) -> Optional[String]
Get nth occurrence of a field.

```mojo
var symbol = msg.get(55)
var second = msg.get(447, 2)  # 2nd occurrence
```

#### __getitem__(tag: Int) -> Optional[String]
Get field value using bracket syntax.

```mojo
var symbol = msg[55]
```

#### __setitem__(tag: Int, value: String)
Set or update field value.

```mojo
msg.__setitem__(55, "MSFT")
```

#### remove(tag: Int, nth: Int = 1) -> Bool
Remove nth occurrence of a field.

```mojo
var removed = msg.remove(54)
```

#### get_all(tag: Int) -> List[String]
Get all occurrences of a tag.

```mojo
var all_values = msg.get_all(447)
```

### Message Operations

#### encode() -> String
Encode message to FIX protocol string.

```mojo
var encoded = msg.encode()
```

#### validate() -> Bool
Validate message structure.

```mojo
if msg.validate():
    print("Valid message")
```

#### clone() -> FixMessage
Create a deep copy of the message.

```mojo
var cloned = msg.clone()
```

#### clear()
Remove all fields from message.

```mojo
msg.clear()
```

#### reset()
Clear and reset message for reuse.

```mojo
msg.reset()
```

#### count_fields() -> Int
Count total fields in message.

```mojo
var count = msg.count_fields()
```

#### has_field(tag: Int) -> Bool
Check if field exists.

```mojo
if msg.has_field(55):
    print("Has Symbol")
```

#### count() -> Int
Count total fields (alias for count_fields).

```mojo
var total = msg.count()
```

---

## FixParser

Parser for FIX protocol messages.

### Creation

```mojo
var parser = FixParser()
var parser_with_config = FixParser(ParserConfig(allow_empty_values=True))
```

### Methods

#### append_buffer(data: String)
Append data to parser buffer.

```mojo
parser.append_buffer(encoded_message)
```

#### get_message() -> Optional[FixMessage]
Extract next complete message from buffer.

```mojo
var msg = parser.get_message()
if msg:
    print("Got message")
```

---

## ParserConfig

Configuration for FIX parser behavior.

### Creation

```mojo
var config = ParserConfig(
    allow_empty_values=True,
    allow_missing_begin_string=False,
    strip_fields_before_begin_string=True
)
```

---

## Zero-Copy Parser

High-performance parser with minimal allocations.

### parse_zero_copy(buffer: String) -> ZeroCopyMessage

```mojo
from mojofix.zero_copy import parse_zero_copy

var zc_msg = parse_zero_copy(encoded)
var symbol = zc_msg.get(55)
```

### ZeroCopyMessage Methods

- `get(tag: Int) -> Optional[String]`
- `count_fields() -> Int`

---

## Buffer Pool

Reusable buffer management for high-frequency scenarios.

### BufferPool

```mojo
from mojofix.buffer_pool import BufferPool

var pool = BufferPool(buffer_size=4096, pool_size=16)
var idx = pool.acquire()
if idx >= 0:
    pool.set_buffer(idx, data)
    var data = pool.get_buffer(idx)
    pool.release(idx)
```

### PooledParser

```mojo
from mojofix.buffer_pool import PooledParser

var parser = PooledParser(pool_size=16)
if parser.acquire_buffer():
    parser.append_data(encoded)
    var data = parser.get_buffer_data()
    parser.release_buffer()
```


---

## Experimental HFT Module

### FastParser

High-performance zero-copy parser (9x faster than safe parser).

```mojo
from mojofix.experimental.hft import FastParser, FastMessage

var parser = FastParser()
var msg = FastMessage("")
parser.parse_into(raw_data, msg)  # Zero-copy parsing
var symbol = msg.get(55)
```

#### Methods

- `parse(data: String) -> FastMessage` - Parse into new message
- `parse_into(data: String, msg: FastMessage)` - Parse into existing message (zero-alloc)

### FastMessage

Zero-copy message representation using field indices.

#### Methods

- `get(tag: Int) -> String` - Get field value
- `get_nth(tag: Int, nth: Int) -> String` - Get nth occurrence
- `has_field(tag: Int) -> Bool` - Check if field exists
- `field_count() -> Int` - Get field count
- `clear()` - Clear all fields for reuse

### FastBuilder

Fast message builder with simplefix-compatible API and buffer reuse.

```mojo
from mojofix.experimental.hft import FastBuilder

var builder = FastBuilder()
builder.append_pair(8, "FIX.4.2")
builder.append_pair(35, "D")
builder.append_pair(55, "AAPL")
builder.append_pair(54, 1)       # Auto-converts Int
builder.append_pair(44, 150.50)  # Auto-converts Float
builder.append_pair(141, True)   # Auto-converts Bool to Y/N

var msg = builder.encode()

# Reuse for next message
builder.reset()
```

#### Methods

**Field Appending:**
- `append_pair(tag: Int, value: String)` - Append string field
- `append_pair(tag: Int, value: Int)` - Append integer field
- `append_pair(tag: Int, value: Float64)` - Append float field
- `append_pair(tag: Int, value: Bool)` - Append boolean field (Y/N)

**Raw Data:**
- `append_data(len_tag: Int, val_tag: Int, data: String)` - Append raw data with length

**Timestamps:**
- `append_utc_timestamp(tag: Int, timestamp: Float64, precision: Int = 3)` - UTC timestamp
- `append_time(tag: Int, timestamp: Float64, precision: Int = 3)` - Alias for append_utc_timestamp

**Message Operations:**
- `encode() -> String` - Finalize and encode message
- `build() -> String` - Alias for encode()
- `reset()` - Clear buffer for reuse (zero-allocation)

> **Performance Note**: FastBuilder currently runs at ~66% of safe builder speed due to string handling overhead. Use for API compatibility and buffer reuse. Performance will improve with future Mojo enhancements.

---

## Performance Tips

1. **Use HFT FastParser** for maximum parsing performance (9x faster)
2. **Use FastBuilder.reset()** for zero-allocation message building in hot loops
3. **Enable buffer pooling** for high-frequency scenarios
4. **Batch operations** when adding multiple fields
5. **Reuse messages** with `reset()` instead of creating new ones
6. **Pre-allocate** when possible

---

**Version:** 1.0  
**Performance:** C/C++ Level  
**Status:** Production-Ready ✅
