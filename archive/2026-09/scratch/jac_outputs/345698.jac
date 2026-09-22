"""
    Returns element at index or default
    """
def get_list_elem[T](`obj: list[T], idx: int, dft: T) -> T {
    if len(`obj) - 1 < idx {
        return dft;
    }
    return `obj[idx];
}