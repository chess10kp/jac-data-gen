"""Function used to compute the distance score (x should be between 0 and 1 but can be a bit greter than 1)"""
def score_distance(x: float) -> float {
    a = 10.0;
    b = 0.5;
    s = 0.2;
    g = 0.18 * x + s;
    f = (1.0 / (b * g) ** 2 - a / (b * g)) * 0.1 * (1.0 - x) / a;
    return min(1.0, -4.82 * f);
}