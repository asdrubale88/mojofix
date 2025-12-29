"""Test parser configuration."""

from testing import assert_equal, assert_true, assert_false
from mojofix.parser import FixParser, ParserConfig
from mojofix.message import FixMessage


fn test_default_config() raises:
    print("Testing default parser configuration...")

    var parser = FixParser()

    # Verify default values
    assert_false(
        parser.config.allow_empty_values,
        "Default should not allow empty values",
    )
    assert_false(
        parser.config.allow_missing_begin_string,
        "Default should require BeginString",
    )
    assert_true(
        parser.config.strip_fields_before_begin_string,
        "Default should strip fields",
    )

    print("✓ Default configuration correct")


fn test_custom_config() raises:
    print("Testing custom parser configuration...")

    var config = ParserConfig(
        allow_empty_values=True,
        allow_missing_begin_string=True,
        strip_fields_before_begin_string=False,
    )

    var parser = FixParser(config)

    # Verify custom values
    assert_true(parser.config.allow_empty_values, "Should allow empty values")
    assert_true(
        parser.config.allow_missing_begin_string,
        "Should allow missing BeginString",
    )
    assert_false(
        parser.config.strip_fields_before_begin_string,
        "Should not strip fields",
    )

    print("✓ Custom configuration correct")


fn test_config_immutability() raises:
    print("Testing configuration is properly set...")

    var config1 = ParserConfig(allow_empty_values=True)
    var config2 = ParserConfig(allow_empty_values=False)

    var parser1 = FixParser(config1)
    var parser2 = FixParser(config2)

    # Verify each parser has its own config
    assert_true(parser1.config.allow_empty_values, "Parser1 should allow empty")
    assert_false(
        parser2.config.allow_empty_values, "Parser2 should not allow empty"
    )

    print("✓ Configuration properly isolated")


fn test_parsing_with_config() raises:
    print("Testing parsing with configuration...")

    # Create a simple message
    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "D")
    msg.append_pair(55, "AAPL")
    var encoded = msg.encode()

    # Parse with default config
    var parser = FixParser()
    parser.append_buffer(encoded)
    var parsed = parser.get_message()

    if parsed:
        var symbol = parsed.value()[55]
        if symbol:
            assert_equal(symbol.value(), "AAPL")
            print("✓ Parsing with config works")
    else:
        raise Error("Should parse message")


fn main() raises:
    print("=" * 60)
    print("PARSER CONFIGURATION TESTS")
    print("=" * 60)

    test_default_config()
    test_custom_config()
    test_config_immutability()
    test_parsing_with_config()

    print("\n" + "=" * 60)
    print("✅ All parser configuration tests passed!")
    print("=" * 60)
