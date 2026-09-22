"""The problem sets the parameters as integers in the range 0-100.
    We'll raise an exception if we receive a type other than int, or if the value
    of that int is not in the right range"""
def compute(x: int, y: int) -> int {
    if `type(x) != int or `type(y) != int {
        raise TypeError('The types of both arguments must be ints');
    }
    if x < 0 or x > 100 or y < 0 or y > 100 {
        raise ValueError('The value of each argument must be in the range 0-100');
    }
    return x + y;
}