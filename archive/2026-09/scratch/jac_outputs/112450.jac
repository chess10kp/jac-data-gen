"""Returns a^b in O(lg n) time complexity, where a and b are both
integers."""
def fast_exp(a: int | float, b: int | float) -> int {
    if not isinstance(a, int) == isinstance(b, int) == True {
        raise TypeError('a and b should both be integers.');
    }
    a = a as int;
    b = b as int;
    if b < 0 {
        return 0;
    }
    result = 1;
    while b != 0 {
        if (b & 1) == 1 {
            result *= a;
        }
        b >>= 1;
        a *= a;
    }
    return result;
}