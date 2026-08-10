"""
Euclide's trick to calculate gcd: perfect for applying recursion.

a, b: positive integers
returns: a positive integer, the greatest common divisor of a & b.
"""
def gcd_recur(a: int, b: int) -> int {
    if b == 0 {
        return a;
    }
    return gcd_recur(b, a % b);
}