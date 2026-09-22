"""Sort three elements in place in ascending order and return the middle index."""
def _median3(comparables: list[int | float | str], lo: int, mid: int, hi: int) -> int {
    if comparables[lo] > comparables[mid] {
        (comparables[lo], comparables[mid]) = (comparables[mid], comparables[lo]);
    }
    if comparables[mid] > comparables[hi] {
        (comparables[mid], comparables[hi]) = (comparables[hi], comparables[mid]);
    }
    if comparables[lo] > comparables[mid] {
        (comparables[lo], comparables[mid]) = (comparables[mid], comparables[lo]);
    }
    return mid;
}