"""Calculate the bandwidth given K."""
def calcbw(K: int, N: int, srate: float) -> float {
    return float(K + 1) * srate / N;
}