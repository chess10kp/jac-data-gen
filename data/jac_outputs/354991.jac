"""
Converts a coordinateHash to a list of tuples.
"""
def coordinateHashToXYTupleList(coordinateHash: dict[int, dict[int, bool]]) -> list[tuple[int, int]] {
    return [(x, y) for (x, ys) in coordinateHash.items() for (y, _) in ys.items()];
}