"""Compute the falling factorial of n to depth k."""
def falling(n: int, k: int) -> int {
    if not k {
        return 1;
    }
    output = n;
    while k != 1 {
        output = output * (n - 1);
        n = n - 1;
        k -= 1;
    }
    return output;
}