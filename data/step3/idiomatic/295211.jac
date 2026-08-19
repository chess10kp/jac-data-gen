glob INT64_MAX = (1 << 63) - 1;
glob UINT32_MASK = 0xFFFFFFFF;
glob INT32_MAX = (1 << 31) - 1;

"""Convert SipHash24 output to Py_hash_t."""
def pysiphash(uint64: int) -> tuple[int, int] {
    assert 0 <= uint64 < (1 << 64);
    if uint64 > INT64_MAX {
        int64 = uint64 - (1 << 64);
    } else {
        int64 = uint64;
    }
    uint32 = (uint64 ^ (uint64 >> 32)) & UINT32_MASK;
    if uint32 > INT32_MAX {
        int32 = uint32 - (1 << 32);
    } else {
        int32 = uint32;
    }
    return (int32, int64);
}
