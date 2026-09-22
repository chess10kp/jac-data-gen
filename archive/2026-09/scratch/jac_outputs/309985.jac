"""Calculate variance of model."""
def model_var_calculate(x: float, p: float, q: float, n: float) -> float {
    def alpha_(x: float) -> float {
        return n * (p * pow(x, 3) + q * (x * x) + (1 - p - q) * x);
    }
    def beta_(x: float) -> float {
        return n - alpha_(x);
    }
    return (alpha_(x) * beta_(x)) / (((alpha_(x) + beta_(x)) ** 2) * (alpha_(x) + beta_(x) + 1));
}