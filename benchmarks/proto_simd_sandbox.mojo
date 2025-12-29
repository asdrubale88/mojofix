from python import Python, PythonObject
from memory import UnsafePointer

# NOTE: Using hardcoded width 32 to bypass missing import issues
alias simd_width = 32


fn find_byte_scalar(ptr: UnsafePointer[UInt8], length: Int, char: UInt8) -> Int:
    for i in range(length):
        if ptr[i] == char:
            return i
    return -1


fn find_byte_simd(ptr: UnsafePointer[UInt8], length: Int, char: UInt8) -> Int:
    var i = 0

    # Vectorized loop
    while i + simd_width <= length:
        # Load 32 bytes
        var chunk = ptr.load[width=simd_width](i)

        # Arithmetic trick: (chunk - char) == 0
        # If scalar broadcasting works for subtraction, this produces a SIMD vector
        var diff = chunk - char
        var zeros = SIMD[DType.uint8, simd_width](0)
        var mask = diff == zeros

        # Reduce: if any element is true
        if mask.reduce_or():
            # Found it, find exact index
            for j in range(simd_width):
                if chunk[j] == char:
                    return i + j
        i += simd_width

    # Handle remaining bytes (tail)
    for j in range(i, length):
        if ptr[j] == char:
            return j

    return -1


fn main() raises:
    print("Initializing SIMD Sandbox (v4 - Arithmetic Trick)...")
    var time_module = Python.import_module("time")

    # Create a large buffer (10MB)
    var size = 10_000_000
    var data = List[UInt8](capacity=size)
    for _ in range(size):
        data.append(ord("A"))

    # Put target at end
    data[size - 1] = ord("=")
    var ptr = data.unsafe_ptr()
    var target = UInt8(ord("="))

    print("Buffer size: 10MB")
    print("Scanning for byte at the very end...")

    # -----------------------------------------------------
    # Benchmark Scalar
    # -----------------------------------------------------
    var t0 = Float64(time_module.time())
    for _ in range(100):
        _ = find_byte_scalar(ptr, size, target)
    var t1 = Float64(time_module.time())

    var time_scalar = t1 - t0
    var gb_scalar = (100.0 * 10.0) / 1024.0 / time_scalar

    print("Scalar Time: " + String(time_scalar) + " s")
    print("Scalar Speed: " + String(Int(gb_scalar * 1000) / 1000.0) + " GB/s")

    # -----------------------------------------------------
    # Benchmark SIMD
    # -----------------------------------------------------
    var t2 = Float64(time_module.time())
    # Warmup
    _ = find_byte_simd(ptr, size, target)

    var t_start_simd = Float64(time_module.time())
    for _ in range(100):
        _ = find_byte_simd(ptr, size, target)
    var t_end_simd = Float64(time_module.time())

    var time_simd = t_end_simd - t_start_simd
    var gb_simd = (100.0 * 10.0) / 1024.0 / time_simd

    print("SIMD Time:   " + String(time_simd) + " s")
    print("SIMD Speed:   " + String(Int(gb_simd * 1000) / 1000.0) + " GB/s")

    var speedup = time_scalar / time_simd
    print("Speedup: " + String(Int(speedup * 100) / 100.0) + "x")
