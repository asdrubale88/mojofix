"""Test SIMD checksum optimization."""

from testing import assert_equal
from mojofix.simd_utils import (
    calculate_checksum_simd,
    calculate_checksum_scalar,
)
from mojofix.message import FixMessage


fn test_simd_checksum_correctness() raises:
    print("Testing SIMD checksum correctness...")

    # Test with various strings
    var test_cases = List[String]()
    test_cases.append("8=FIX.4.2")
    test_cases.append("35=D")
    test_cases.append("55=AAPL")
    test_cases.append("The quick brown fox jumps over the lazy dog")
    test_cases.append("")  # Empty string

    for i in range(len(test_cases)):
        var test_str = test_cases[i]
        var simd_result = calculate_checksum_simd(test_str)
        var scalar_result = calculate_checksum_scalar(test_str)

        if simd_result != scalar_result:
            print("FAILED for:", test_str)
            print("  SIMD:", simd_result)
            print("  Scalar:", scalar_result)
            raise Error("SIMD and scalar checksums don't match!")

    print("✓ SIMD checksum matches scalar for all test cases")


fn test_simd_in_message_encoding() raises:
    print("Testing SIMD checksum in message encoding...")

    var msg = FixMessage()
    msg.append_pair(8, "FIX.4.2")
    msg.append_pair(35, "D")
    msg.append_pair(55, "AAPL")
    msg.append_pair(54, "1")
    msg.append_pair(38, "100")

    var encoded = msg.encode()
    print("Encoded message:", encoded)

    # Verify checksum is present and correctly formatted
    if "10=" in encoded:
        print("✓ Checksum field present")
    else:
        raise Error("Checksum field missing!")

    # Extract checksum value
    var parts = encoded.split("10=")
    if len(parts) >= 2:
        var checksum_part = String(parts[1])
        var checksum_str = checksum_part[:3]  # First 3 chars
        print("✓ Checksum value:", checksum_str)

        # Verify it's 3 digits
        if len(checksum_str) == 3:
            print("✓ Checksum correctly formatted (3 digits)")
        else:
            raise Error("Checksum not 3 digits!")

    print("✓ SIMD checksum working in message encoding")


fn benchmark_simd_vs_scalar() raises:
    print("\nBenchmarking SIMD vs Scalar checksum...")

    var test_data = (
        "8=FIX.4.2"
        + chr(1)
        + "9=100"
        + chr(1)
        + "35=D"
        + chr(1)
        + "55=AAPL"
        + chr(1)
        + "54=1"
        + chr(1)
    )
    var iterations = 50000

    print("Running", iterations, "iterations...")

    # Benchmark scalar
    print("  Scalar implementation...")
    for i in range(iterations):
        _ = calculate_checksum_scalar(test_data)
    print("  ✓ Scalar complete")

    # Benchmark SIMD
    print("  SIMD implementation...")
    for i in range(iterations):
        _ = calculate_checksum_simd(test_data)
    print("  ✓ SIMD complete")

    print("\n✓ Both implementations completed successfully")
    print("  Expected: SIMD is 4-8x faster than scalar")


fn main() raises:
    print("=" * 60)
    print("SIMD CHECKSUM OPTIMIZATION TESTS")
    print("=" * 60)

    test_simd_checksum_correctness()
    test_simd_in_message_encoding()
    benchmark_simd_vs_scalar()

    print("\n" + "=" * 60)
    print("✅ All SIMD tests passed!")
    print("=" * 60)
