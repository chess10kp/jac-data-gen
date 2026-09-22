"""Returns True if GPS segment ``a`` overlaps GPS segment ``b``
    """
def segments_overlap(a: Any, b: Any) -> object {
    return ((a[1] > b[0]) and (a[0] < b[1]));
}