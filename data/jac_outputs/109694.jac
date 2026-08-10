"""Index -> {(idx_row, idx_col): bool})."""
def _is_visible(idx_row: int, idx_col: int, lengths: dict[tuple[int, int], bool]) -> bool {
    return (idx_col, idx_row) in lengths;
}