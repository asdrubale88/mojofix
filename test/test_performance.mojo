"""Comprehensive performance benchmarks for mojofix.

Measures parsing throughput, encoding throughput, latency, and memory efficiency
to establish baseline metrics and compare with simplefix.
"""

from time import perf_counter_ns
from mojofix.message import FixMessage
from mojofix.parser import FixParser


fn benchmark_parsing_throughput() raises:
    """Benchmark parsing throughput (messages/second)."""
    print("Benchmark: Parsing Throughput...")

    # Create a realistic FIX message
    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.4")
    msg.append_pair(35, "D")
    msg.append_pair(11, "ORDER-001")
    msg.append_pair(55, "AAPL")
    msg.append_pair(54, "1")
    msg.append_pair(38, "100")
    msg.append_pair(40, "2")
    msg.append_pair(44, "150.50")

    var encoded = msg.encode()

    # Warm up
    for i in range(100):
        var parser = FixParser()
        parser.append_buffer(encoded)
        var _ = parser.get_message()

    # Benchmark
    var iterations = 10000
    var start = perf_counter_ns()

    for i in range(iterations):
        var parser = FixParser()
        parser.append_buffer(encoded)
        var _ = parser.get_message()

    var end = perf_counter_ns()
    var duration_ns = end - start
    var duration_s = Float64(duration_ns) / 1_000_000_000.0
    var throughput = Float64(iterations) / duration_s

    print("  Iterations:", iterations)
    print("  Duration:", duration_s, "seconds")
    print("  Throughput:", Int(throughput), "messages/second")
    print(
        "  Latency:",
        (duration_s / Float64(iterations)) * 1_000_000,
        "microseconds/message",
    )
    print("✓ PASS")


fn benchmark_encoding_throughput() raises:
    """Benchmark encoding throughput (messages/second)."""
    print("\nBenchmark: Encoding Throughput...")

    # Warm up
    for i in range(100):
        var msg = FixMessage()
        msg.append_pair(8, "FIX.4.4")
        msg.append_pair(35, "D")
        msg.append_pair(55, "MSFT")
        var _ = msg.encode()

    # Benchmark
    var iterations = 10000
    var start = perf_counter_ns()

    for i in range(iterations):
        var msg = FixMessage()
        msg.append_pair(8, "FIX.4.4")
        msg.append_pair(35, "D")
        msg.append_pair(11, "ORDER-" + String(i))
        msg.append_pair(55, "MSFT")
        msg.append_pair(54, "1")
        msg.append_pair(38, "100")
        msg.append_pair(40, "2")
        msg.append_pair(44, "280.75")
        var _ = msg.encode()

    var end = perf_counter_ns()
    var duration_ns = end - start
    var duration_s = Float64(duration_ns) / 1_000_000_000.0
    var throughput = Float64(iterations) / duration_s

    print("  Iterations:", iterations)
    print("  Duration:", duration_s, "seconds")
    print("  Throughput:", Int(throughput), "messages/second")
    print(
        "  Latency:",
        (duration_s / Float64(iterations)) * 1_000_000,
        "microseconds/message",
    )
    print("✓ PASS")


fn benchmark_roundtrip_latency() raises:
    """Benchmark full round-trip (encode + parse) latency."""
    print("\nBenchmark: Round-Trip Latency...")

    # Warm up
    for i in range(100):
        var msg = FixMessage()
        msg.append_pair(8, "FIX.4.4")
        msg.append_pair(35, "D")
        msg.append_pair(55, "GOOGL")
        var encoded = msg.encode()
        var parser = FixParser()
        parser.append_buffer(encoded)
        var _ = parser.get_message()

    # Benchmark
    var iterations = 10000
    var start = perf_counter_ns()

    for i in range(iterations):
        var msg = FixMessage()
        msg.append_pair(8, "FIX.4.4")
        msg.append_pair(35, "D")
        msg.append_pair(55, "GOOGL")
        msg.append_pair(54, "2")
        msg.append_pair(38, "50")

        var encoded = msg.encode()

        var parser = FixParser()
        parser.append_buffer(encoded)
        var _ = parser.get_message()

    var end = perf_counter_ns()
    var duration_ns = end - start
    var duration_s = Float64(duration_ns) / 1_000_000_000.0
    var throughput = Float64(iterations) / duration_s

    print("  Iterations:", iterations)
    print("  Duration:", duration_s, "seconds")
    print("  Throughput:", Int(throughput), "round-trips/second")
    print(
        "  Latency:",
        (duration_s / Float64(iterations)) * 1_000_000,
        "microseconds/round-trip",
    )
    print("✓ PASS")


fn benchmark_large_message_parsing() raises:
    """Benchmark parsing of large messages (100 fields)."""
    print("\nBenchmark: Large Message Parsing...")

    # Create large message
    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.4")
    msg.append_pair(35, "D")

    for i in range(100, 200):
        msg.append_pair(i, "VALUE_" + String(i))

    var encoded = msg.encode()

    # Warm up
    for i in range(100):
        var parser = FixParser()
        parser.append_buffer(encoded)
        var _ = parser.get_message()

    # Benchmark
    var iterations = 5000
    var start = perf_counter_ns()

    for i in range(iterations):
        var parser = FixParser()
        parser.append_buffer(encoded)
        var _ = parser.get_message()

    var end = perf_counter_ns()
    var duration_ns = end - start
    var duration_s = Float64(duration_ns) / 1_000_000_000.0
    var throughput = Float64(iterations) / duration_s

    print("  Message size: 100 fields")
    print("  Iterations:", iterations)
    print("  Duration:", duration_s, "seconds")
    print("  Throughput:", Int(throughput), "messages/second")
    print(
        "  Latency:",
        (duration_s / Float64(iterations)) * 1_000_000,
        "microseconds/message",
    )
    print("✓ PASS")


fn benchmark_stream_parsing() raises:
    """Benchmark parsing message stream (multiple messages in buffer)."""
    print("\nBenchmark: Stream Parsing...")

    # Create 10 messages in a stream
    var stream = String()
    for i in range(10):
        var msg = FixMessage()
        msg.append_pair(8, "FIX.4.4")
        msg.append_pair(35, "0")  # Heartbeat
        stream += msg.encode()

    # Warm up
    for i in range(100):
        var parser = FixParser()
        parser.append_buffer(stream)
        for j in range(10):
            var _ = parser.get_message()

    # Benchmark
    var iterations = 1000
    var start = perf_counter_ns()

    for i in range(iterations):
        var parser = FixParser()
        parser.append_buffer(stream)
        for j in range(10):
            var _ = parser.get_message()

    var end = perf_counter_ns()
    var duration_ns = end - start
    var duration_s = Float64(duration_ns) / 1_000_000_000.0
    var total_messages = iterations * 10
    var throughput = Float64(total_messages) / duration_s

    print("  Messages per stream: 10")
    print("  Iterations:", iterations)
    print("  Total messages:", total_messages)
    print("  Duration:", duration_s, "seconds")
    print("  Throughput:", Int(throughput), "messages/second")
    print("✓ PASS")


fn benchmark_field_access() raises:
    """Benchmark field access performance."""
    print("\nBenchmark: Field Access...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.4")
    msg.append_pair(35, "D")
    msg.append_pair(55, "TSLA")
    msg.append_pair(54, "1")
    msg.append_pair(38, "100")

    # Warm up
    for i in range(1000):
        var _ = msg[55]
        var _ = msg[54]
        var _ = msg[38]

    # Benchmark
    var iterations = 100000
    var start = perf_counter_ns()

    for i in range(iterations):
        var _ = msg[55]
        var _ = msg[54]
        var _ = msg[38]

    var end = perf_counter_ns()
    var duration_ns = end - start
    var duration_s = Float64(duration_ns) / 1_000_000_000.0
    var accesses = iterations * 3
    var throughput = Float64(accesses) / duration_s

    print("  Iterations:", iterations)
    print("  Total accesses:", accesses)
    print("  Duration:", duration_s, "seconds")
    print("  Throughput:", Int(throughput), "accesses/second")
    print(
        "  Latency:",
        (duration_s / Float64(accesses)) * 1_000_000_000,
        "nanoseconds/access",
    )
    print("✓ PASS")


fn main() raises:
    print("=" * 70)
    print("MOJOFIX PERFORMANCE BENCHMARKS")
    print("Measuring throughput, latency, and efficiency")
    print("=" * 70)

    benchmark_parsing_throughput()
    benchmark_encoding_throughput()
    benchmark_roundtrip_latency()
    benchmark_large_message_parsing()
    benchmark_stream_parsing()
    benchmark_field_access()

    print("\n" + "=" * 70)
    print("✅ ALL BENCHMARKS COMPLETE!")
    print("=" * 70)
    print("\nPerformance Summary:")
    print("  • Parsing: Measured ✅")
    print("  • Encoding: Measured ✅")
    print("  • Round-trip: Measured ✅")
    print("  • Large messages: Measured ✅")
    print("  • Stream parsing: Measured ✅")
    print("  • Field access: Measured ✅")
    print("\nBaseline metrics established for future regression testing!")
