"""Computes an exponent in a modulus without overflowing."""
def mod_exp(val: int, exp: int, modulus: int) -> int {
    return pow(int(val), int(exp), int(modulus));
}