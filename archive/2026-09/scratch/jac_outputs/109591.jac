"""calc distance between two 3d points"""
def distance(point1: list[float], point2: list[float]) -> float {
    return (
        (point1[0] - point2[0]) ** 2
        + (point1[1] - point2[1]) ** 2
        + (point1[2] - point2[2]) ** 2
    ) ** 0.5;
}