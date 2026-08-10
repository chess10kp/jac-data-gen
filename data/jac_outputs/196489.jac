"""
This is general fib method.
"""
def fibab(n: int, a: int, b: int) -> int {
    if n < 2 {
        return 1;
    }
    return a * fibab(n - 1, a, b) + b * fibab(n - 2, a, b);
}