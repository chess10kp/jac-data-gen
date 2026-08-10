"""Arduino's map function — linear range remapping."""
def ard_map(
    value: float,
    in_min: float,
    in_max: float,
    out_min: float,
    out_max: float
) -> float {
    return out_min + (out_max - out_min) * ((value - in_min) / (in_max - in_min));
}