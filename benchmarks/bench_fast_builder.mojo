"""Benchmark FastBuilder vs safe FixMessage builder."""

from python import Python
from mojofix.message import FixMessage
from mojofix.experimental.hft import FastBuilder


fn main() raises:
    print("=" * 70)
    print("MOJOFIX: HFT FASTBUILDER vs SAFE FIXMESSAGE BENCHMARK")
    print("=" * 70)

    var time_module = Python.import_module("time")
    var iterations = 100_000
    print("\nIterations:", iterations)
    print("Message: FIX.4.2 NewOrderSingle with 10 fields\n")

    # Warm up
    print("Warming up...")
    var warmup_msg = FixMessage()
    warmup_msg.append_pair(8, "FIX.4.2")
    warmup_msg.append_pair(35, "D")
    warmup_msg.append_pair(49, "SENDER")
    warmup_msg.append_pair(56, "TARGET")
    warmup_msg.append_pair(55, "AAPL")
    warmup_msg.append_pair(54, 1)
    warmup_msg.append_pair(38, 100)
    warmup_msg.append_pair(44, 150.50)
    _ = warmup_msg.encode()

    var warmup_fast = FastBuilder()
    warmup_fast.append_pair(8, "FIX.4.2")
    warmup_fast.append_pair(35, "D")
    warmup_fast.append_pair(49, "SENDER")
    warmup_fast.append_pair(56, "TARGET")
    warmup_fast.append_pair(55, "AAPL")
    warmup_fast.append_pair(54, 1)
    warmup_fast.append_pair(38, 100)
    warmup_fast.append_pair(44, 150.50)
    _ = warmup_fast.encode()

    # Benchmark SAFE Builder
    print("\n" + "-" * 70)
    print("SAFE FIXMESSAGE BUILDER (Heap-based, fully safe)")
    print("-" * 70)

    var t0_safe = time_module.time()
    for _ in range(iterations):
        var msg = FixMessage()
        msg.append_pair(8, "FIX.4.2")
        msg.append_pair(35, "D")
        msg.append_pair(49, "SENDER")
        msg.append_pair(56, "TARGET")
        msg.append_pair(55, "AAPL")
        msg.append_pair(54, 1)
        msg.append_pair(38, 100)
        msg.append_pair(44, 150.50)
        msg.append_pair(40, "2")
        msg.append_pair(59, "0")
        _ = msg.encode()
    var t1_safe = time_module.time()
    var safe_time = t1_safe - t0_safe

    var safe_throughput = iterations / safe_time
    var safe_latency_us = (safe_time / iterations) * 1_000_000

    print("Time:      ", safe_time, "seconds")
    print("Throughput:", safe_throughput, "msg/sec")
    print("Latency:   ", safe_latency_us, "μs/msg")

    # Benchmark FAST Builder (New Allocation)
    print("\n" + "-" * 70)
    print("HFT FASTBUILDER (Allocation Mode)")
    print("-" * 70)

    var t0_fast = time_module.time()
    for _ in range(iterations):
        var builder = FastBuilder()
        builder.append_pair(8, "FIX.4.2")
        builder.append_pair(35, "D")
        builder.append_pair(49, "SENDER")
        builder.append_pair(56, "TARGET")
        builder.append_pair(55, "AAPL")
        builder.append_pair(54, 1)
        builder.append_pair(38, 100)
        builder.append_pair(44, 150.50)
        builder.append_pair(40, "2")
        builder.append_pair(59, "0")
        _ = builder.encode()
    var t1_fast = time_module.time()
    var fast_time = t1_fast - t0_fast

    var fast_throughput = iterations / fast_time
    var fast_latency_us = (fast_time / iterations) * 1_000_000

    print("Time:      ", fast_time, "seconds")
    print("Throughput:", fast_throughput, "msg/sec")
    print("Latency:   ", fast_latency_us, "μs/msg")

    # Benchmark FAST Builder (Reuse Mode)
    print("\n" + "-" * 70)
    print("HFT FASTBUILDER (Reuse Mode - Zero Alloc)")
    print("-" * 70)

    var reused_builder = FastBuilder()
    var t0_reuse = time_module.time()
    for _ in range(iterations):
        reused_builder.reset()
        reused_builder.append_pair(8, "FIX.4.2")
        reused_builder.append_pair(35, "D")
        reused_builder.append_pair(49, "SENDER")
        reused_builder.append_pair(56, "TARGET")
        reused_builder.append_pair(55, "AAPL")
        reused_builder.append_pair(54, 1)
        reused_builder.append_pair(38, 100)
        reused_builder.append_pair(44, 150.50)
        reused_builder.append_pair(40, "2")
        reused_builder.append_pair(59, "0")
        _ = reused_builder.encode()
    var t1_reuse = time_module.time()
    var reuse_time = t1_reuse - t0_reuse

    var reuse_throughput = iterations / reuse_time
    var reuse_latency_us = (reuse_time / iterations) * 1_000_000

    print("Time:      ", reuse_time, "seconds")
    print("Throughput:", reuse_throughput, "msg/sec")
    print("Latency:   ", reuse_latency_us, "μs/msg")

    # Benchmark FAST Builder (Comp Tags)
    print("\n" + "-" * 70)
    print("HFT FASTBUILDER (Comp Tags - Zero Alloc + Comptime)")
    print("-" * 70)

    var comp_builder = FastBuilder()
    var t0_comp = time_module.time()
    for _ in range(iterations):
        comp_builder.reset()
        # Use compile-time known tags where possible (mostly string/char fields)
        comp_builder.append_comp_tag[8]("FIX.4.2")
        comp_builder.append_comp_tag[35]("D")
        comp_builder.append_comp_tag[49]("SENDER")
        comp_builder.append_comp_tag[56]("TARGET")
        comp_builder.append_comp_tag[55]("AAPL")
        # For numeric values, we currently still use append_pair but could optimize further
        comp_builder.append_pair(54, 1)
        comp_builder.append_pair(38, 100)
        comp_builder.append_pair(44, 150.50)
        comp_builder.append_comp_tag[40]("2")
        comp_builder.append_comp_tag[59]("0")
        _ = comp_builder.encode()
    var t1_comp = time_module.time()
    var comp_time = t1_comp - t0_comp

    var comp_throughput = iterations / comp_time
    var comp_latency_us = (comp_time / iterations) * 1_000_000

    print("Time:      ", comp_time, "seconds")
    print("Throughput:", comp_throughput, "msg/sec")
    print("Latency:   ", comp_latency_us, "μs/msg")

    # Results Analysis
    var speedup_alloc = safe_time / fast_time
    var speedup_reuse = safe_time / reuse_time
    var speedup_comp = safe_time / comp_time

    print("\n" + "=" * 70)
    print("RESULTS")
    print("=" * 70)
    print("Safe Builder Throughput:     ", Int(safe_throughput), "msg/s")
    print("Fast Builder (Alloc):        ", Int(fast_throughput), "msg/s")
    print("Fast Builder (Reuse):        ", Int(reuse_throughput), "msg/s")
    print("Fast Builder (Comp Tags):    ", Int(comp_throughput), "msg/s")
    print("Speedup (Alloc) vs Safe:     ", speedup_alloc, "x")
    print("Speedup (Reuse) vs Safe:     ", speedup_reuse, "x")
    print("Speedup (Comp) vs Safe:      ", speedup_comp, "x")

    print("\nPERFORMANCE ANALYSIS")
    print("-" * 70)
    print("1. Buffer Reuse is Critical: Reusing the builder provides")
    print("   significant speedup by avoiding buffer allocations.")
    print("2. Memory Efficiency: FastBuilder uses pre-allocated buffer")
    print("   vs FixMessage which allocates List + FixField per field.")
    print("3. Unsafe Operations: FastBuilder writes directly to bytes")
    print("   avoiding intermediate String allocations.")

    if speedup_reuse > 2.0:
        print(
            "\n✅ FastBuilder (Reuse) is SIGNIFICANTLY FASTER than Safe Builder."
        )
    elif speedup_reuse > 1.0:
        print("\n✅ FastBuilder (Reuse) is FASTER than Safe Builder.")
    else:
        print("\n⚠️ FastBuilder (Reuse) is comparable to Safe Builder.")
        print("   Further optimization needed.")
    print("=" * 70)
