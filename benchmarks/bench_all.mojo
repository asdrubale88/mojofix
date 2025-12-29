"""Benchmark suite for mojofix performance testing.

Measures:
- Message creation speed
- Message parsing speed  
- Checksum calculation speed
- Timestamp formatting speed
- Overall throughput
"""

from time import time
from mojofix.message import FixMessage
from mojofix.parser import FixParser
from mojofix.time_utils import format_utc_timestamp


fn benchmark_message_creation(iterations: Int) -> Float64:
    """Benchmark message creation speed."""
    var start = time()

    for i in range(iterations):
        var msg = FixMessage()
        msg.append_pair(8, "FIX.4.2")
        msg.append_pair(35, "D")
        msg.append_pair(55, "AAPL")
        msg.append_pair(54, "1")
        msg.append_pair(38, "100")
        msg.append_pair(44, "150.50")
        msg.append_pair(40, "2")
        _ = msg.encode()

    var end = time()
    return end - start


fn benchmark_message_parsing(iterations: Int) -> Float64:
    """Benchmark message parsing speed."""
    # Create a test message
    var test_msg = FixMessage()
    test_msg.append_pair(8, "FIX.4.2")
    test_msg.append_pair(35, "D")
    test_msg.append_pair(55, "MSFT")
    test_msg.append_pair(54, "1")
    test_msg.append_pair(38, "200")
    var encoded = test_msg.encode()

    var start = time()

    for i in range(iterations):
        var parser = FixParser()
        parser.append_buffer(encoded)
        var parsed = parser.get_message()

    var end = time()
    return end - start


fn benchmark_timestamp_formatting(iterations: Int) -> Float64:
    """Benchmark timestamp formatting speed."""
    var timestamp: Float64 = 1705318245.123456

    var start = time()

    for i in range(iterations):
        _ = format_utc_timestamp(timestamp, precision=3)

    var end = time()
    return end - start


fn benchmark_checksum_calculation(iterations: Int) -> Float64:
    """Benchmark checksum calculation speed."""
    var test_msg = FixMessage()
    test_msg.append_pair(8, "FIX.4.2")
    test_msg.append_pair(35, "D")
    test_msg.append_pair(55, "AAPL")
    test_msg.append_pair(54, "1")
    test_msg.append_pair(38, "100")
    test_msg.append_pair(44, "150.50")

    var start = time()

    for i in range(iterations):
        _ = test_msg.encode()  # Includes checksum calculation

    var end = time()
    return end - start


fn format_number(value: Float64, decimals: Int = 2) -> String:
    """Format a number with specified decimal places."""
    var int_part = Int(value)
    var frac_part = Int((value - Float64(int_part)) * Float64(10**decimals))
    if frac_part < 0:
        frac_part = -frac_part
    var frac_str = String(frac_part)
    while len(frac_str) < decimals:
        frac_str = "0" + frac_str
    return String(int_part) + "." + frac_str


fn main() raises:
    print("=" * 60)
    print("MOJOFIX PERFORMANCE BENCHMARKS")
    print("=" * 60)

    var warmup_iterations = 100
    var benchmark_iterations = 10000

    print("\nWarming up...")
    _ = benchmark_message_creation(warmup_iterations)

    # Message Creation Benchmark
    print("\n" + "=" * 60)
    print("1. MESSAGE CREATION")
    print("=" * 60)
    var creation_time = benchmark_message_creation(benchmark_iterations)
    var creation_per_msg = (
        creation_time / Float64(benchmark_iterations)
    ) * 1_000_000  # microseconds
    var creation_throughput = Float64(benchmark_iterations) / creation_time

    print("Iterations:", benchmark_iterations)
    print("Total time:", format_number(creation_time, 3), "seconds")
    print("Time per message:", format_number(creation_per_msg, 2), "μs")
    print("Throughput:", format_number(creation_throughput, 0), "msg/s")

    # Message Parsing Benchmark
    print("\n" + "=" * 60)
    print("2. MESSAGE PARSING")
    print("=" * 60)
    var parsing_time = benchmark_message_parsing(benchmark_iterations)
    var parsing_per_msg = (
        parsing_time / Float64(benchmark_iterations)
    ) * 1_000_000
    var parsing_throughput = Float64(benchmark_iterations) / parsing_time

    print("Iterations:", benchmark_iterations)
    print("Total time:", format_number(parsing_time, 3), "seconds")
    print("Time per message:", format_number(parsing_per_msg, 2), "μs")
    print("Throughput:", format_number(parsing_throughput, 0), "msg/s")

    # Timestamp Formatting Benchmark
    print("\n" + "=" * 60)
    print("3. TIMESTAMP FORMATTING (Native Mojo)")
    print("=" * 60)
    var timestamp_time = benchmark_timestamp_formatting(benchmark_iterations)
    var timestamp_per_op = (
        timestamp_time / Float64(benchmark_iterations)
    ) * 1_000_000
    var timestamp_throughput = Float64(benchmark_iterations) / timestamp_time

    print("Iterations:", benchmark_iterations)
    print("Total time:", format_number(timestamp_time, 3), "seconds")
    print("Time per operation:", format_number(timestamp_per_op, 2), "μs")
    print("Throughput:", format_number(timestamp_throughput, 0), "ops/s")

    # Checksum Calculation Benchmark
    print("\n" + "=" * 60)
    print("4. CHECKSUM CALCULATION")
    print("=" * 60)
    var checksum_time = benchmark_checksum_calculation(benchmark_iterations)
    var checksum_per_op = (
        checksum_time / Float64(benchmark_iterations)
    ) * 1_000_000
    var checksum_throughput = Float64(benchmark_iterations) / checksum_time

    print("Iterations:", benchmark_iterations)
    print("Total time:", format_number(checksum_time, 3), "seconds")
    print("Time per operation:", format_number(checksum_per_op, 2), "μs")
    print("Throughput:", format_number(checksum_throughput, 0), "ops/s")

    # Summary
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(
        "Message Creation:     ", format_number(creation_per_msg, 2), "μs/msg"
    )
    print("Message Parsing:      ", format_number(parsing_per_msg, 2), "μs/msg")
    print("Timestamp Formatting: ", format_number(timestamp_per_op, 2), "μs/op")
    print("Checksum Calculation: ", format_number(checksum_per_op, 2), "μs/op")
    print(
        "\nOverall Throughput:   ",
        format_number(creation_throughput, 0),
        "msg/s",
    )

    print("\n" + "=" * 60)
    print("OPTIMIZATION TARGETS")
    print("=" * 60)
    print("Current timestamp: ", format_number(timestamp_per_op, 2), "μs")
    print("Target (Phase 4):   0.30 μs (25x faster than Python)")
    print("\nCurrent checksum:  ", format_number(checksum_per_op, 2), "μs")
    print(
        "Target (SIMD):      ",
        format_number(checksum_per_op / 6.0, 2),
        "μs (4-8x speedup)",
    )
    print(
        "\nCurrent throughput:", format_number(creation_throughput, 0), "msg/s"
    )
    print("Target (Phase 4):   500,000+ msg/s")

    print("\n" + "=" * 60)
    print("✅ Benchmark complete!")
    print("=" * 60)
