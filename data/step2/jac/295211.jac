"""Convert SipHash24 output to Py_hash_t
    """
def pysiphash(uint64: Any) -> object {
    assert (0 <= uint64 < (1 << 64));
    if (uint64 > ((1 << 63) - 1)) {
        int64 = uint64 - (1 << 64);
    } else {
        int64 = uint64;
    }
    uint32 = (uint64 ^ (uint64 >> 32)) & 4294967295;
    if (uint32 > ((1 << 31) - 1)) {
        int32 = uint32 - (1 << 32);
    } else {
        int32 = uint32;
    }
    return (int32, int64);
}
with entry {
    assert (pysiphash(17) == (17, 17));
    assert (pysiphash(1) == (1, 1));
    assert (pysiphash(7) == (7, 7));
    assert (pysiphash(6) == (6, 6));
    assert (pysiphash(16) == (16, 16));
    assert (pysiphash(8) == (8, 8));
    assert (pysiphash(3) == (3, 3));
    assert (pysiphash(9) == (9, 9));
    assert (pysiphash(22) == (22, 22));
    assert (pysiphash(14) == (14, 14));
    assert (pysiphash(15) == (15, 15));
    assert (pysiphash(2) == (2, 2));
    assert (pysiphash(13) == (13, 13));
    assert (pysiphash(18) == (18, 18));
    assert (pysiphash(21) == (21, 21));
    assert (pysiphash(0) == (0, 0));
    assert (pysiphash(4) == (4, 4));
    assert (pysiphash(19) == (19, 19));
    assert (pysiphash(11) == (11, 11));
    assert (pysiphash(5) == (5, 5));
    assert (pysiphash(12) == (12, 12));
    assert (pysiphash(10) == (10, 10));
    assert (pysiphash(20) == (20, 20));
}

