"""Return the factorial of a number."""
def factorial(n: int) -> int {
    if n < 0 {
        raise ValueError("factorial() not defined for negative values");
    }
    result = 1;
    for i in range(1, n + 1) {
        result *= i;
    }
    return result;
}