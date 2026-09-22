"""Counts the number of elements in an iterator, consuming it and making it
unavailable for any other purpose."""
def ilen(iterator: list[int]) -> int {
    sum(1 for _ in iterator)
}