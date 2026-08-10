"""Return the complement of a list of integers, as compared to
a given "universe" set. If no universe is specified,
consider the universe to be all integers between
the minimum and maximum values of the given list."""
def complement(l: list[int], universe: list[int] | set[int] | None = None) -> list[int] {
    if universe is not None {
        universe = set(universe);
    } else {
        universe = set(range(min(l), max(l) + 1));
    }
    return sorted(universe - set(l));
}