from mojofix.simd_utils import calculate_checksum_simd


fn main():
    print("SIMD Utils imported successfully")
    print(calculate_checksum_simd("8=FIX"))
