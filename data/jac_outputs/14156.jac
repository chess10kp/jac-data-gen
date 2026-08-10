"""
Calculate the factorial of a positive integer.
https://en.wikipedia.org/wiki/Factorial
"""
def factorial(n: int) -> int {
    if not isinstance(n, int) {
        raise ValueError("factorial() only accepts integral values");
    }
    if n < 0 {
        raise ValueError("factorial() not defined for negative values");
    }
    return 1 if n == 0 or n == 1 else n * factorial(n - 1);
}