"""Return the string representation of n in base-b."""
def base_b(n: int, b: int) -> str {
    e = n // b;
    q = n % b;
    if n == 0 {
        return '0';
    } elif e == 0 {
        return str(q);
    } else {
        return base_b(e, b) + str(q);
    }
}