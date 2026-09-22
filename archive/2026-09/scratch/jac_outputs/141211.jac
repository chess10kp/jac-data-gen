"""Dimensionless geometry coefficient lambda2."""
def get_lam2(membrane_geometry: str) -> float {
    match membrane_geometry {
        case 'FMM':
            return 3 / 2.0;
        case 'FMS':
            return 3 / 4.0;
        case _:
            return 4.0;
    }
}