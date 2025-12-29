# Examples

This directory contains usage examples for Mojofix.

## Running Examples

```bash
# Basic usage
pixi run example-basic

# Message parsing
pixi run example-parsing

# Timestamp handling
pixi run example-timestamps
```

## Available Examples

### [basic_usage.mojo](basic_usage.mojo)
Demonstrates:
- Creating a FIX message
- Adding fields
- Encoding messages
- Accessing field values

### [parsing.mojo](parsing.mojo)
Demonstrates:
- Parsing FIX messages
- Extracting field values
- Message validation

### [timestamps.mojo](timestamps.mojo)
Demonstrates:
- UTC timestamps
- Timezone-aware timestamps
- Date-only fields
- Time-only fields

## More Examples

For more advanced usage, see:
- [API Documentation](../API.md)
- [Test Suite](../test/) - Comprehensive examples of all features
- [Benchmarks](../benchmarks/) - Performance-oriented examples
