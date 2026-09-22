"""Calculates the sum of the square differences of the components of
    v1 and v2 vectors.
    """
def sum_of_square_difference(v1: list[float], v2: list[float]) -> float {
    sum = 0.0;
    for (c1, c2) in zip(v1, v2) {
        t = c1 - c2;
        sum += t * t;
    }
    return sum;
}