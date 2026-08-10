"""
    Create and return 1-D array
    :param size:
    :param fill_default: Default value to be filled in cells.
    :return:
    """
def empty_1d_array(size: int, fill_default: int | float | str | bool | None = None) -> list[int | float | str | bool | None] {
    return [fill_default] * size;
}