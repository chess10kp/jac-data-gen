"""If num isn't a power of 2, will return the next higher power of two."""
def next_p2(num: int) -> int {
    rval = 1;
    while rval < num {
        rval <<= 1;
    }
    return rval;
}