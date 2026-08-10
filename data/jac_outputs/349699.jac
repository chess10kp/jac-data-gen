"""Estimate incoming solar radiation for an island location (FAO equation 51)."""
def sol_rad_island(et_rad: float) -> float {
    return 0.7 * et_rad - 4.0;
}