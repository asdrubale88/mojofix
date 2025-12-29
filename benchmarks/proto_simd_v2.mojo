"""Prototype SIMD scanning for HFT parser - V2."""

from python import Python
from memory import UnsafePointer
from sys import simdwidthof
import sys


fn benchmark_scalar(ptr: UnsafePointer[UInt8], length: Int, char: Int) -> Int:
    for i in range(length):
        if Int(ptr[i]) == char:
            return i
    return -1


fn benchmark_simd(ptr: UnsafePointer[UInt8], length: Int, char: Int) -> Int:
    alias scale = simdwidthof[DType.uint8]()
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

    # Create a large buffer
    var size = 10_000_000
    var buf = String(" " * size)
    var ptr = buf.unsafe_ptr()

    # Place target at the end
    # Use array syntax for store
    ptr[size - 1] = UInt8(ord("X"))
    var target = ord("X")

    var time_module = Python.import_module("time")
    var iterations = 100

    # Benchmark Scalar
    var t0 = time_module.time()
    for _ in range(iterations):
        _ = benchmark_scalar(ptr, size, target)
    var t1 = time_module.time()
    var scalar_time = t1 - t0

    # Benchmark SIMD
    var t2 = time_module.time()
    for _ in range(iterations):
        _ = benchmark_simd(ptr, size, target)
    var t3 = time_module.time()
    var simd_time = t3 - t2

    print("Data size:      ", size, "bytes")
    print("Scalar time:    ", scalar_time, "s")
    print("SIMD time:      ", simd_time, "s")
    print("Speedup factor: ", scalar_time / simd_time, "x")
