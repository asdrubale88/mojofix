"""Prototype SIMD scanning for HFT parser - V4."""

from python import Python
from memory import UnsafePointer
from mojofix.simd_utils import simdwidthof


fn benchmark_scalar(ptr: UnsafePointer[UInt8], length: Int, char: Int) -> Int:
    for i in range(length):
        if Int(ptr[i]) == char:
            return i
    return -1


fn benchmark_simd(ptr: UnsafePointer[UInt8], length: Int, char: Int) -> Int:
    comptime scale = simdwidthof[DType.uint8]()
    var i = 0
    var val = SIMD[DType.uint8, scale](char)

    # Process vectorized chunks
    while i + scale <= length:
        var chunk = ptr.load[width=scale](i)
        var mask = chunk == val
        if mask.reduce_or():
            # Found it, find exact position
            for j in range(scale):
                if chunk[j] == char:
                    return i + j
        i += scale

    # Process remaining scalar
    for j in range(i, length):
        if Int(ptr[j]) == char:
            return j

    return -1


fn main() raises:
    print("=" * 60)
    print("SIMD SCANNING PROTOTYPE")
    print("=" * 60)

    var size = 10_000_000
    var buf = String(" " * size)
    var ptr = buf.unsafe_ptr()

    # Write to pointer using store() if array syntax fails due to mutability checks
    # Or just reconstruct string to have the char
    # But since we have UnsafePointer, let's use a workaround if needed
    # ptr.store(size-1, UInt8(ord("X"))) -> This API might be gone.

    # Alternative: construct string with "X" at end
    var buf2 = String(" " * (size - 1)) + "X"
    var ptr2 = buf2.unsafe_ptr()
    var target = ord("X")

    var time_module = Python.import_module("time")
    var iterations = 100

    # Benchmark Scalar
    var t0 = time_module.time()
    for _ in range(iterations):
        _ = benchmark_scalar(ptr2, size, target)
    var t1 = time_module.time()
    var scalar_time = t1 - t0

    # Benchmark SIMD
    var t2 = time_module.time()
    for _ in range(iterations):
        _ = benchmark_simd(ptr2, size, target)
    var t3 = time_module.time()
    var simd_time = t3 - t2

    print("Data size:      ", size, "bytes")
    print("Scalar time:    ", scalar_time, "s")
    print("SIMD time:      ", simd_time, "s")
    print("Speedup factor: ", scalar_time / simd_time, "x")
