"""Convert a base-10 integer to base-N."""
def number_to_base(n: int, base: int) -> list[int] {
    if base < 2 {
        raise ValueError('Base cannot be less than 2.');
    }
    if n < 0 {
        sign = -1;
        n *= sign;
    } elif n == 0 {
        return [0];
    } else {
        sign = 1;
    }
    digits = [];
    while n {
        digits.append(sign * int(n % base));
        n //= base;
    }
    return digits[::-1];
}