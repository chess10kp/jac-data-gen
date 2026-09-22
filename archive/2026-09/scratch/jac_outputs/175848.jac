"""Like ord(), but takes multiple characters. I.e. calculate the
base10 equivalent of a string considered as a set of base-256 digits."""
def multiord(x: str) -> int {
    num = 0;
    scale = 1;
    for ch in reversed(x) {
        num = num + ord(ch) * scale;
        scale = scale * 256;
    }
    return num;
}