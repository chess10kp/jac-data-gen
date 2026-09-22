"""
    check if elements of a list are increasing monotonically.
    """
def non_increasing(py_list: list[float]) -> bool {
    return all(x >= y for (x, y) in zip(py_list, py_list[1:]));
}