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

test "t0" {
    assert (pysiphash(17) == (17, 17));;
}

test "t1" {
    assert (pysiphash(1) == (1, 1));;
}

test "t2" {
    assert (pysiphash(7) == (7, 7));;
}

test "t3" {
    assert (pysiphash(6) == (6, 6));;
}

test "t4" {
    assert (pysiphash(16) == (16, 16));;
}

test "t5" {
    assert (pysiphash(8) == (8, 8));;
}

test "t6" {
    assert (pysiphash(3) == (3, 3));;
}

test "t7" {
    assert (pysiphash(9) == (9, 9));;
}

test "t8" {
    assert (pysiphash(22) == (22, 22));;
}

test "t9" {
    assert (pysiphash(14) == (14, 14));;
}

test "t10" {
    assert (pysiphash(15) == (15, 15));;
}

test "t11" {
    assert (pysiphash(2) == (2, 2));;
}

test "t12" {
    assert (pysiphash(13) == (13, 13));;
}

test "t13" {
    assert (pysiphash(18) == (18, 18));;
}

test "t14" {
    assert (pysiphash(21) == (21, 21));;
}

test "t15" {
    assert (pysiphash(0) == (0, 0));;
}

test "t16" {
    assert (pysiphash(4) == (4, 4));;
}

test "t17" {
    assert (pysiphash(19) == (19, 19));;
}

test "t18" {
    assert (pysiphash(11) == (11, 11));;
}

test "t19" {
    assert (pysiphash(5) == (5, 5));;
}

test "t20" {
    assert (pysiphash(12) == (12, 12));;
}

test "t21" {
    assert (pysiphash(10) == (10, 10));;
}

test "t22" {
    assert (pysiphash(20) == (20, 20));;
}

