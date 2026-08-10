"""Return sorted list as copy."""
def radix_sort(vals: list[int]) -> list[int] {
    if len(vals) <= 1 {
        return vals[:];
    }
    digits = len(str(max(vals)));
    for power in range(digits) {
        buckets = [[] for _ in range(10)];
        for val in vals {
            trunc_val = val % (10 ** (power + 1));
            idx = trunc_val // (10 ** power);
            buckets[idx].append(val);
        }
        vals = [val for bucket in buckets for val in bucket];
    }
    return vals;
}