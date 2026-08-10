"""Compute the difference between two lists."""
def diff(first: list[int], second: list[int]) -> list[int] {
    second_set = set(second);
    return [item for item in first if item not in second_set];
}