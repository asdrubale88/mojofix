# Contributing to Mojofix

Thank you for your interest in contributing to Mojofix! This document provides guidelines and instructions for contributing.

## Development Setup

### Prerequisites
- Mojo >= 0.26.1
- pixi package manager

### Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/mojofix
   cd mojofix
   ```

2. **Install dependencies**
   ```bash
   pixi install
   ```

3. **Run tests**
   ```bash
   pixi run test
   ```

## Project Structure

```
mojofix/
├── src/mojofix/          # Source code
│   ├── message.mojo      # FixMessage implementation
│   ├── parser.mojo       # FixParser implementation
│   ├── time_utils.mojo   # Timestamp utilities
│   ├── simd_utils.mojo   # SIMD optimizations
│   └── hft/              # HFT module (experimental)
├── test/                 # Test suites
├── benchmarks/           # Performance benchmarks
└── examples/             # Usage examples
```

## Running Tests

### All Tests
```bash
# Run simplefix compatibility suite
pixi run test

# Run individual test files
pixi run mojo -I src test/test_message.mojo
pixi run mojo -I src test/test_parser.mojo
pixi run mojo -I src test/test_data_fields.mojo
```

### Benchmarks
```bash
pixi run mojo -I src bench_throughput.mojo
pixi run mojo -I src benchmarks/bench_phase1_opts.mojo
```

## Code Style

### Mojo Style Guidelines
- Use 4 spaces for indentation
- Maximum line length: 100 characters
- Use descriptive variable names
- Add docstrings to all public functions and structs
- Follow Mojo naming conventions:
  - `snake_case` for functions and variables
  - `PascalCase` for structs and types
  - `UPPER_CASE` for constants

### Documentation
- All public APIs must have docstrings
- Include parameter descriptions and return values
- Add usage examples for complex features

### Example
```mojo
fn parse_message(data: String) raises -> FixMessage:
    \"\"\"Parse a FIX message from string.
    
    Args:
        data: Raw FIX message string with SOH delimiters.
        
    Returns:
        Parsed FixMessage object.
        
    Raises:
        Error if message is malformed.
    \"\"\"
    # Implementation...
```

## Testing Guidelines

### Writing Tests
- Add tests for all new features
- Ensure backward compatibility
- Test edge cases and error conditions
- Use descriptive test names

### Test Structure
```mojo
fn test_feature_name() raises:
    \"\"\"Test description.\"\"\"
    print(\"Test: feature_name...\")
    
    # Setup
    var msg = FixMessage()
    
    # Execute
    msg.append_pair(55, \"AAPL\")
    
    # Assert
    assert_true(msg.has_field(55), \"Should have field 55\")
    
    print(\"✓ PASS\")
```

## Pull Request Process

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write code
   - Add tests
   - Update documentation

3. **Run tests**
   ```bash
   pixi run test
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m \"feat: add your feature description\"
   ```

5. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   ```

### Commit Message Format
Follow conventional commits:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `test:` Test additions/changes
- `perf:` Performance improvements
- `refactor:` Code refactoring

## Performance Considerations

When contributing performance-critical code:
- Benchmark before and after changes
- Avoid unnecessary allocations
- Consider SIMD optimizations where applicable
- Document performance characteristics

## Questions?

Feel free to open an issue for:
- Bug reports
- Feature requests
- Questions about contributing
- Discussion of implementation details

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
