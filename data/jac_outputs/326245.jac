"""Returns the area of a trapezoid."""
def trapezoid_area(base_minor: float, base_major: float, height: float) -> float {
    return height * (base_minor + base_major) / 2;
}