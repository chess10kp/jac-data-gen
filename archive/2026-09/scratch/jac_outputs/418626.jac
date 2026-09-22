"""Returns the distance between two points."""
def getDistance(origin: list[float], point: list[float]) -> float {
    return ((origin[0] - point[0]) ** 2 + (origin[1] - point[1]) ** 2) ** 0.5;
}