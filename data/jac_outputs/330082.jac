"""Flattens the provided list of lists."""
def _flatten(list_of_lists: list[list[object]]) -> list[object] {
    [val for sublist in list_of_lists for val in sublist]
}