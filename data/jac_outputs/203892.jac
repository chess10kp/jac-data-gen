"""Returns min element (or None if there are no elements)."""
def min_(xs: list[int]) -> int | None {
    if len(xs) == 0 {
        return None;
    }
    return min(xs);
}