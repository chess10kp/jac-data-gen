"""check unit cell."""
def good_unit_cell(uc_params: list[float], target_unit_cell: list[float], uc_tol: float) -> bool {
    return all(
        abs(uc_params[i] - target_unit_cell[i]) <= uc_tol * target_unit_cell[i] / 100
        for i in range(6)
    );
}