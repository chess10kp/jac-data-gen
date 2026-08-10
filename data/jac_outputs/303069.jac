"""Returns a list containing the items found in sublists of lst."""
def flatten(lst: list[list[int]]) -> list[int] {
    [item for sublist in lst for item in sublist]
}