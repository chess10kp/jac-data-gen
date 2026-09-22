"""Bucket the counts by powers of two."""
def bucketFeatByCount(featCount: int) -> int {
    for i in range(11) {
        size = 2 ** i;
        if featCount <= size {
            return size;
        }
    }
    return -1;
}