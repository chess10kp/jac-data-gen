"""
    Finds the maximum length of a bucket in buckets (dict as returned by bucket_sort)
    """
def max_bucket_len(buckets: dict[int, list[int]]) -> int {
    m = 1;
    for v in buckets.values() {
        m = max(m, len(v));
    }
    return m;
}