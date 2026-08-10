"""Find the highest common factor of two numbers."""
def find_hcf(a: int, b: int) -> int {
    if b == 0 {
        return a;
    }
    return find_hcf(b, a % b);
}