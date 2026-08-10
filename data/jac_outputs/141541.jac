"""
        Calculates very large GCD
        Uses squaring for calculating residue
        Complexity: O(log(n))
    """
def mGCD(a: int, b: int, m: int = 1) -> int {
    a1 = a % m;
    p = 1;
    b_val = float(b);
    while b_val > 0 {
        if b_val % 2 == 1 {
            p *= a1;
            p = p % m;
        }
        b_val /= 2;
        a1 = (a1 * a1) % m;
    }
    return p;
}