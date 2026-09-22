"""Find a custom score for cigar."""
def cigar_score(
    pairs: list[tuple[str, int]],
    match_score: int = 1,
    mismatch_score: int = -1,
    gap_score: int = -1
) -> int {
    total = 0;
    for (c, i) in pairs {
        if c == "=" {
            total += i * match_score;
        } elif c == "X" {
            total += i * mismatch_score;
        } elif c in ("I", "D", "N", "S", "H", "P") {
            total += i * gap_score;
        }
    }
    total
}