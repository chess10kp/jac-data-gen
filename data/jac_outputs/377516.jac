"""For [[1, 2], [3, 4]] returns [1, 2, 3, 4]. Does not recurse."""
def flatten(seq: list[list[int]]) -> list[int] {
    return [x for sub in seq for x in sub];
}