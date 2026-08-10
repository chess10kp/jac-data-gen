"""GCD(x:long, y:long): long
    Return the GCD of x and y.
    """
def GCD(x: int, y: int) -> int {
    x = abs(x);
    y = abs(y);
    while x > 0 {
        (x, y) = (y % x, x);
    }
    return y;
}