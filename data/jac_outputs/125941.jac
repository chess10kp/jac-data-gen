"""Obtain a score of a value according to a histogram, between 0.0 and 1.0."""
def _check_histogram(hist: tuple[list[float], list[float]], value: int | float) -> float {
    i = 0;
    while i < len(hist[1]) and value > hist[1][i] {
        i += 1;
    }
    if i == 0 or i == len(hist[1]) {
        return 0.0;
    }
    return hist[0][i - 1];
}