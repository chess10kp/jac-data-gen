"""Return the first rank that this hand has exactly n of.
    Return None if there no n-of-a-kind in the hand."""
def kind(n: int, ranks: list[int]) -> int | None {
    for r in ranks {
        if ranks.count(r) == n {
            return r;
        }
    }
    return None;
}