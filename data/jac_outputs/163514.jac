"""Calculate cdd according to Meteorological Office equations (Day 2006)."""
def calc_met_equation_cdd(`case: int, t_min: float, t_max: float, t_base: float) -> float {
    match `case {
        case 1:
            cdd = 0.5 * (t_max + t_min) - t_base;
        case 2:
            cdd = 0.5 * (t_max - t_base) - 0.25 * (t_base - t_min);
        case 3:
            cdd = 0.25 * (t_max - t_base);
        case _:
            cdd = 0;
    }
    return cdd;
}