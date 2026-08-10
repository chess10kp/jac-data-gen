"""Unique a seq and keep its original order."""
def stable_unique(seq: Sequence[int]) -> list[int] {
    seen = set();
    seen_add = seen.add;
    return [x for x in seq if not (x in seen or seen_add(x))];
}