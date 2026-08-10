"""Return a sequence in the same order, but with duplicates removed."""
def Dedup(seq: list[str | int]) -> list[str | int] {
    seen = set();
    result: list[str | int] = [];
    for s in seq {
        if s not in seen {
            result.append(s);
        }
        seen.add(s);
    }
    return result;
}