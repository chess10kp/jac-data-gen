"""Finds first and last elements in a list."""
def first_and_last(a: list[object]) -> list[object] {
    if not isinstance(a, list) {
        raise TypeError;
    }
    if len(a) < 2 {
        raise IndexError;
    }
    return [a[0], a[-1]];
}