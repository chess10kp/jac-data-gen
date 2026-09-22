"""Modular exponential of a number."""
def mod_exponent(base: int, power: int, mod: int) -> int {
    res = 1;
    base = base % mod;
    while power > 0 {
        if power & 1 {
            res = (res * base) % mod;
        }
        power = power >> 1;
        base = (base * base) % mod;
    }
    return res;
}