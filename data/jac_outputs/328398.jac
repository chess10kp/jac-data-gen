"""Get the prev element in the array."""
def get_prev_element(array: list[object], index: int) -> int {
    if index == 0 {
        return len(array) - 1;
    }
    return index - 1;
}