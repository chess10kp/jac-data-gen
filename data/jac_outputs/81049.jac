"""Append list with element and return the list modified."""
def append(l: list[int], elem: int | None) -> list[int] {
    if elem is not None {
        l.append(elem);
    }
    return l;
}