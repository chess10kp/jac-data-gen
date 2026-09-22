"""Round down an integer to a multiple of divider."""
def round_down(rounded: Any, divider: Any) -> object {
    return ((int(rounded) // divider) * divider);
}