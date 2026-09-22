"""Return the sum of all positive integer
multiples of k less than or equal to n,
i.e. sum_multiple(k, n) = k + 2k + ... + k floor(n/k)."""
def sum_multiple(k: int, n: int) -> float {
    N = n / k;
    return k * N * (N + 1) / 2;
}