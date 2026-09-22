""" The GCD (greatest common divisor) is the highest number that evenly divides both width and height. """
def get_gcd(a: int, b: int) -> int {
    return a if b == 0 else get_gcd(b, a % b);
}