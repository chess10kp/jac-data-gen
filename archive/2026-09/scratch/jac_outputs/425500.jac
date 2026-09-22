"""Return matrix * scalar."""
def matscalarMul(mat: list[list[int | float]], scalar: int | float) -> tuple[tuple[int | float, ...], ...] {
    dim = len(mat);
    return tuple(
        tuple(mat[i][j] * scalar for j in range(dim))
        for i in range(dim)
    );
}