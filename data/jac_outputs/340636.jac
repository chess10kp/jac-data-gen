"""Maps x and y from a range to another, desired range."""
def map_to_range(
    start_val: float,
    current_range_min: float,
    current_range_max: float,
    wanted_range_min: float,
    wanted_range_max: float
) -> float {
    out_range = wanted_range_max - wanted_range_min;
    in_range = current_range_max - current_range_min;
    in_val = start_val - current_range_min;
    val = (float(in_val) / in_range) * out_range;
    out_val = wanted_range_min + val;
    return out_val;
}