"""Returns whether x is (in turn order) between begin (inclusive) and end
(inclusive). This function assumes that x,
begin, end are smaller than the number of players (and at least 0).
If begin == end, this is only true if x == begin == end."""
def is_between_inclusive(x: int, begin: int, end: int) -> bool {
    return begin <= x <= end or end < begin <= x or x <= end < begin;
}