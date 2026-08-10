def Legendre_poly(n: int, x: float) -> float | int {
    if n == 0 {
        return 1;
    } elif n == 1 {
        return x;
    }
    return (
        ((2 * n) - 1) * x * Legendre_poly(n - 1, x) - (n - 1) * Legendre_poly(n - 2, x)
    ) / float(n);
}