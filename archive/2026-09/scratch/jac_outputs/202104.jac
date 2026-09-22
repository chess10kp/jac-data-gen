"""Return core dense keys in the right format."""
def return_core_dense_key(core_idx: int, dense: bool | int = False) -> tuple[int, int | bool] {
    if dense is False {
        return (core_idx, 0);
    }
    return (core_idx, dense);
}