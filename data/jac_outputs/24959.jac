"""Recursive solution."""
def recursive_factorial(num: int) -> int {
    if num >= 2 {
        return num * recursive_factorial(num - 1);
    }
    return 1;
}