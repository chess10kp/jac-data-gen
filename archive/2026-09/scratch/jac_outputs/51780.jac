"""
    converts base 26 number-char into decimal
    :param x:
    :return:
    """
def _x2n(x: str) -> int {
    numerals = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    b = 26;
    n = 0;
    for (i, letter) in enumerate(reversed(x)) {
        n += (numerals.index(letter) + 1) * (b ** i);
    }
    return n;
}