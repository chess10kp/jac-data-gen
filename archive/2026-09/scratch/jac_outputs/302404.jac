"""little-endian"""
def uint_to_bit_list(n: int, bits: int = 32) -> list[int] {
    [(1 & (n >> i)) for i in range(bits)]
}