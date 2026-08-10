"""Determine the index of greatest byte that isn't all zeros, and
    return the bitmap that contains all the bytes less than that index.
    """
def _truncate_bitmap(what: bytes) -> bytes {
    for i in range(len(what) - 1, -1, -1) {
        if what[i] != 0 {
            return what[0:i + 1];
        }
    }
    return what[0:1];
}