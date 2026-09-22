glob INT32_MIN = -(2 ** 31);
glob INT32_MAX = (2 ** 31) - 1;

"""Reverse an integer."""
def reverse_int(integer: int) -> int {
    reversed_int = int(str(abs(integer))[::-1]);
    if integer < 0 {
        reversed_int *= -1;
    }
    return reversed_int if INT32_MIN < reversed_int < INT32_MAX else 0;
}