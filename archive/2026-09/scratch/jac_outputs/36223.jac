"""straight 3-d euclidean distance (assume RGB)"""
def pixel_distance(p1: list[float], p2: list[float]) -> float {
    ((p1[0] - p2[0]) ** 2 + (p1[1] - p2[1]) ** 2 + (p1[2] - p2[2]) ** 2) ** 0.5
}