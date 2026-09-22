"""Return the matrix size for the given (Micro) QR Code version."""
def calc_matrix_size(ver: int) -> int {
    return (ver * 4 + 17) if ver > 0 else (ver + 4) * 2 + 9;
}