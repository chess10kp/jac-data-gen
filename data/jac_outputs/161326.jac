"""Return the global alignment score for two amino acids."""
def score_global(x: str, y: str) -> int {
    if x == y {
        return 5;
    }
    return -4;
}