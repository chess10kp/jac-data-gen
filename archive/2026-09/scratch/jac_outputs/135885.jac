"""Calculate the area of a trapezium."""
def area_trapezium(base1: float, base2: float, height: float) -> float {
    if base1 < 0 or base2 < 0 or height < 0 {
        raise ValueError("area_trapezium() only accepts non-negative values");
    }
    (1 / 2) * (base1 + base2) * height
}