"""Checks indices whether is empty."""
def check_indices(indices_size: int, index: int) -> int {
    if indices_size < 1 {
        raise IndexError("The tensor's index is unreasonable. index:{}".format(index));
    }
    return indices_size;
}