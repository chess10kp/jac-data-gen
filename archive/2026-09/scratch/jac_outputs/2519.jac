"""Rotate a single character n places in the alphabet
    n is an integer
    """
def rotate_char(c: str, n: int) -> str {
    if c.islower() {
        alpha_base = ord('a');
    } elif c.isupper() {
        alpha_base = ord('A');
    } else {
        return c;
    }
    alpha_number = ord(c) - alpha_base;
    new_alpha_number = (alpha_number + n) % 26;
    return chr(alpha_base + new_alpha_number);
}