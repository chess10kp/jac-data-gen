"""
Assuming (factor * k) % base == value, return v such that k % base == v.
Also assumes that base is prime.
"""
def simplify_mod_product(base: int, factor: int, value: int) -> int {
    return [i for i in range(base) if factor * i % base == value][0];
}