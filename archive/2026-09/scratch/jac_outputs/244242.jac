"""Helper function to calculate the distance between node a and b."""
def calculate_distance(a: tuple[float, float], b: tuple[float, float]) -> float {
    (x1, y1) = a;
    (x2, y2) = b;
    return ((x1 - x2) ** 2 + (y1 - y2) ** 2) ** 0.5;
}