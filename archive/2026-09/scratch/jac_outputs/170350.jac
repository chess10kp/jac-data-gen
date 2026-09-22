glob UINT64_MASK = 0xFFFFFFFFFFFFFFFF;
glob HASH_MULTIPLIER = 2862933555777941757;

"""Generate a number in the range [0, num_buckets)."""
def py_hash(key: int, num_buckets: int) -> int {
    (b, j) = (-1, 0.0);
    if num_buckets < 1 {
        raise ValueError(f"'num_buckets' must be a positive number, got {num_buckets}");
    }
    while j < num_buckets {
        b = int(j);
        key = (key * HASH_MULTIPLIER + 1) & UINT64_MASK;
        j = float(b + 1) * (float(1 << 31) / float((key >> 33) + 1));
    }
    return int(b);
}