"""returns the augmented matrix,
    assuming A is a square matrix"""
def augmented_matrix(A: list[list[int]], b: list[int]) -> list[list[int]] {
    (aug, n) = ([], len(A));
    for i in range(n) {
        t = A[i];
        t.append(b[i]);
        aug.append(t);
    }
    return aug;
}