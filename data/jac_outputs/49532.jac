"""Takes two inputs and returns the Greatest common divisor and returns it"""
def GCD(x: int, y: int) -> int {
    while y {
        (x, y) = (y, x % y);
    }
    return x;
}