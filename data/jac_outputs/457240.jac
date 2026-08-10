"""Return n! - the factorial of n."""
def factorial(n: int) -> int {
    if n <= 0 {
        return 0;
    } elif n == 1 {
        return 1;
    } else {
        return n * factorial(n - 1);
    }
}