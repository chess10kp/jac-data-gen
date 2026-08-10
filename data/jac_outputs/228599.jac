"""Given two vectors, returns the manhatten distance between them.

    Requires that they are the same dimension.
    """
def manhatten_distance(first: list[float], second: list[float]) -> float {
    if len(first) != len(second) {
        raise Exception("These vectors must be the same size");
    }
    return sum([abs(x - y) for (x, y) in zip(first, second)]);
}