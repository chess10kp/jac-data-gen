"""Flatten several lists into one list."""
def flatten_lists(*lists: list[int]) -> list[int] {
    [x for sublist in lists for x in sublist]
}