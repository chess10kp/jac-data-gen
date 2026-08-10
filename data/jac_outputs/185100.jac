"""Compute non-unique union of many intervals."""
def interval_union(start: list[int], stop: list[int]) -> list[int] {
    return [i for rng in zip(start, stop) for i in range(*rng)];
}