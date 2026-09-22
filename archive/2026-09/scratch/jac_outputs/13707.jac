glob UINT64_MASK = 0xFFFFFFFFFFFFFFFF;

"""Right rotate the number x by c bits for 64-bit numbers."""
def rightrotate_64(x: int, c: int) -> int {
    x &= UINT64_MASK;
    return ((x >> c) | (x << (64 - c))) & UINT64_MASK;
}