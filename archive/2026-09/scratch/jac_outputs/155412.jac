"""Math is fun (Thanks Adrien and Eric)."""
def binomial_coeff(n: int, k: int) -> float {
    k = min(k, n - k);
    n_acc = 1;
    for i in range(n, n - k, -1) {
        n_acc *= i;
    }
    d_acc = 1;
    for i in range(1, k + 1) {
        d_acc *= i;
    }
    return n_acc / d_acc;
}