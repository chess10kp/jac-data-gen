"""Return a copy of sequence that is rotated right by one element."""
def rotate_r(sequence: list[int]) -> list[int] {
    sequence[-1:] + sequence[:-1]
}