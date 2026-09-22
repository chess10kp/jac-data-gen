"""Returns true if two sets are not overlapping."""
def check_for_overlap(a: list[object] | set[object], b: list[object] | set[object]) -> bool {
    return set(a).isdisjoint(b);
}