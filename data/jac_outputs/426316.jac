"""Retain a specified number of compcor components."""
def _select_compcor(compcor_cols: list[str], n_compcor: int | str) -> list[str] {
    if n_compcor != "auto" and n_compcor < len(compcor_cols) {
        compcor_cols = compcor_cols[0:n_compcor];
    }
    return compcor_cols;
}