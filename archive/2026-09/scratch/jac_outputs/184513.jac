"""Precompute the future padded size."""
def compute_padding(M: int, N: int, J: int) -> tuple[int, int] {
    M_padded = ((M + (2 ** J)) // (2 ** J) + 1) * (2 ** J);
    N_padded = ((N + (2 ** J)) // (2 ** J) + 1) * (2 ** J);
    return (M_padded, N_padded);
}