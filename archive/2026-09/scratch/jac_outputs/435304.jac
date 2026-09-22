"""Return the left child index for a heap element at index i."""
def left(i: int) -> int {
    return i * 2 + 1;
}