"""Flattens a nested list."""
def flatten_list(l: list[list[int]]) -> list[int] {
    return [x for nl in l for x in nl];
}