"""Mean normalization of input x, given dataset mean, max, and min."""
def mean_normalize(x: float, mean_x: float, max_x: float, min_x: float) -> float {
    if max_x - min_x == 0 {
        return x;
    }
    return (x - mean_x) / (max_x - min_x);
}