"""Mapping (row, column, spin-type) to Jordan-Wigner encoding."""
def map_rcs_to_JW(nh: int, nv: int, row: int, col: int, spin: int) -> int {
    col_adjust = col;
    if row % 2 == 1 {
        col_adjust = nh - 1 - col;
    }
    return row * nh + col_adjust + nh * nv * spin;
}