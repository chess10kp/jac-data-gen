"""Perform z-score normalization of a signal."""
def normalize(x: float, x_mean: float, x_std: float) -> float {
    return (x - x_mean) / x_std;
}