"""Sum up to n using recursion."""
def fun1(n: int) -> int {
    if n == 0 {
        return 0;
    }
    return n + fun1(n - 1);
}