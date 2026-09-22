"""
    We shall say that an n-digit number is pandigital
    if it makes use of all the digits 1 to n exactly once;
    for example, the 5-digit number, 15234, is 1 through 5 pandigital.

    A number is said to be pandigital if it contains each of the digits
    from 0 to 9 (and whose leading digit must be nonzero).
    However, "zeroless" pandigital quantities contain the digits 1 through 9.
    Sometimes exclusivity is also required so that each digit is restricted
    to appear exactly once. For example, 6729/13458 is a (zeroless, restricted)
    pandigital fraction and 1023456789 is the smallest
    (zerofull) pandigital number.

    The first few zerofull restricted pandigital
    numbers are 1023456789, 1023456798,
    1023456879, 1023456897, 1023456978, ...
    """
def is_pandigital(digit: str) -> bool {
    digit_str = str(digit);
    digit_set = set(int(d) for d in digit_str);
    if len(digit_set) != len(digit_str) {
        return False;
    }
    pattern = set(n for n in range(min(digit_set), max(digit_set) + 1));
    return digit_set == pattern;
}