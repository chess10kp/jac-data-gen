"""Split list seq into n list."""
def chunks(seq: list[int], n: int) -> list[list[int]] {
    [seq[i::n] for i in range(n)]
}