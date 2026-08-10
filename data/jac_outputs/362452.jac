"""Flattens the list l."""
def flatten(l: list[list[int]]) -> list[int] {
    return [item for sublist in l for item in sublist];
}