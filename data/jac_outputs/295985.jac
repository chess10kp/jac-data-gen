"""Check if a string checksum char in the base10 representation is correct."""
def calc_AIC_base10_checksum(code: str) -> str {
    xn = [2 * int(code[i]) for i in (1, 3, 5, 7)];
    p = 0;
    for x in xn {
        p = p + x // 10 + x % 10;
    }
    d = 0;
    for i in (0, 2, 4, 6) {
        d = d + int(code[i]);
    }
    return str((p + d) % 10);
}