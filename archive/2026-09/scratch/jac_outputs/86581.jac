"""Fill A or B with zeros if not the same size."""
def fillIfNeeded(A: list[int], B: list[int]) -> tuple[list[int], list[int]] {
    A = list(A)[:];
    B = list(B)[:];
    if len(A) < len(B) {
        A += [0] * (len(B) - len(A));
    }
    if len(B) < len(A) {
        B += [0] * (len(A) - len(B));
    }
    return (A, B);
}