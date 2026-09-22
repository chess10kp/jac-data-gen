"""
    Convert from degrees to km - approximate.
    """
def distance_km(point1: list[float], point2: list[float]) -> float {
    return ((point1[0] - point2[0]) ** 2 + (point1[1] - point2[1]) ** 2) ** 0.5 * 111;
}