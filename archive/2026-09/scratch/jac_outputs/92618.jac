"""Return the ith triplet in a sequence."""
def _triplet(seq: str, i: int) -> str {
    start = i * 3;
    return seq[start:(start + 3)];
}