"""Returns a list."""
def listify(x: int | str | list[int]) -> list[int] | str | list[int] {
    if not hasattr(x, '__len__') {
        return [x];
    }
    return x;
}