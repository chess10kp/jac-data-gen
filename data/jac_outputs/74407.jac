"""Calculate kurtosis in data N from averages <N^4>, <N^3>, <N^2>, and <N>."""
def kurtosis(N: float, N2: float, N3: float, N4: float, **kwargs: dict[str, str]) -> float {
    return ((-3 * (N ** 4)) + (6 * (N ** 2) * N2) - (4 * N * N3) + N4) / ((N2 - (N ** 2)) ** 2);
}