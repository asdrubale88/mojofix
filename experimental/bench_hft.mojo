"""Benchmark HFT module vs safe implementation."""

from python import Python
from mojofix.hft import ArenaParser
from mojofix.parser import FixParser
from mojofix.message import FixMessage


fn benchmark_hft_parsing(iterations: Int) raises:
    """Benchmark HFT zero-copy parser."""
    print("Benchmarking HFT PARSING (zero-copy)...")
    var time_module = Python.import_module("time")

    var parser = ArenaParser()
    var msg_str = "8=FIX.4.2\x019=40\x0135=D\x0155=AAPL\x0154=1\x0138=100\x0144=150.50\x0110=000\x01"

    var t0 = time_module.time()

    for i in range(iterations):
        var msg = parser.parse_message(msg_str)
        _ = msg.get(55)  # Access a field
        # Arena automatically reused (no reset needed for single message)

    var t1 = time_module.time()
    var duration = t1 - t0

    var mps = iterations / duration
    print("HFT Parsing Throughput:", mps, " msg/sec")
    print("Total time:", duration, "s for", iterations, "messages")


fn benchmark_safe_parsing(iterations: Int) raises:
    """Benchmark safe heap-based parser."""
    print("\nBenchmarking SAFE PARSING (heap-based)...")
    var time_module = Python.import_module("time")

    var parser = FixParser()
    var msg_str = "8=FIX.4.2\x019=40\x0135=D\x0155=AAPL\x0154=1\x0138=100\x0144=150.50\x0110=000\x01"

    var t0 = time_module.time()

    for i in range(iterations):
        parser.buffer = ""
        parser.append_buffer(msg_str)
        var msg = parser.get_message()
        if msg:
            _ = msg.value().get(55)

    var t1 = time_module.time()
    var duration = t1 - t0

    var mps = iterations / duration
    print("Safe Parsing Throughput:", mps, " msg/sec")
    print("Total time:", duration, "s for", iterations, "messages")


fn main() raises:
    print("=" * 60)
    print("HFT vs SAFE IMPLEMENTATION BENCHMARK")
    print("=" * 60)

    var iterations = 1_000_000

    benchmark_hft_parsing(iterations)
    benchmark_safe_parsing(iterations)

    print("\n" + "=" * 60)
    print("Expected: HFT should be 3-6x faster")
    print("=" * 60)
