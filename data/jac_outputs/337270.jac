"""
    If the object is not a list already, it converts it to one
    Examples:
    [1, 2, 3] -> [1, 2, 3]
    [1] -> [1]
    1 -> [1]
    """
def make_list[T](v: T | list[T]) -> list[T] {
    if not isinstance(v, list) {
        return [v];
    }
    return v;
}