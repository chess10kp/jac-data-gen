"""
    Given two dicts, merge them into a new dict as a shallow copy
    """
def merge_two_dicts(x: dict[str, object], y: dict[str, object]) -> dict[str, object] {
    z = x.copy();
    z.update(y);
    return z;
}