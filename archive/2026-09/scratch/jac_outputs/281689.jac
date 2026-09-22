""" returns the factorial of n """
def factorial(n: int) -> int | None {
    if n < 0 {
        return None;
    }
    if n == 0 {
        return 1;
    }
    if n < 2 {
        return 1;
    }
    return n * factorial(n - 1);
}