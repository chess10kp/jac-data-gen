"""Like (elt in seq), but compares with is, not ==."""
def isin(elt: object, seq: list[object]) -> bool {
    return any(elt is x for x in seq);
}