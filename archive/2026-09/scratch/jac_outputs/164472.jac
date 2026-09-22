"""Newton's method with poor initial guess of n."""
def newton(n: float, error: float) -> float {
    x = n;
    while abs(x ** 2 - n) > error {
        x = x - (x ** 2 - n) / (2 * x);
    }
    return x;
}