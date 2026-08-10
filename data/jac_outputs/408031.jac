"""Flatten a list of lists, leaving tuples intact."""
def flatten(S: list[list[int]]) -> list[int] {
    return [val for sublist in S for val in sublist];
}