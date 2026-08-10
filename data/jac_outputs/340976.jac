"""
    Applies the predicate to each item, taking the disjunction of the results.
    Will add d as a disjunct, and then finally will take that in
    conjunction with c. Returns the value.
    """
def build_mask[T](
    items: list[T],
    predicate: Callable[[T], int],
    d: int | None = None,
    c: int | None = None
) -> int | None {
    q: int | None = None;
    for i in items {
        if q is None {
            q = predicate(i);
        } else {
            q |= predicate(i);
        }
    }
    if d is not None {
        q = d | q;
    }
    if c is not None {
        q = c & q;
    }
    return q;
}