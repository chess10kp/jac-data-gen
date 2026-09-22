"""Sort tuples alphabetically."""
def reorder_tuple(input_tuple: tuple[tuple[str, ...], tuple[str, ...]]) -> tuple[tuple[str, ...], tuple[str, ...]] {
    if input_tuple[0][0] > input_tuple[1][0] {
        return tuple((input_tuple[1], input_tuple[0]));
    }
    return tuple((input_tuple[0], input_tuple[1]));
}