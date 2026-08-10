"""True if j divides i"""
def divides(i: int, j: int) -> bool {
    if j == 0 {
        return False;
    }
    return (i % j) == 0;
}