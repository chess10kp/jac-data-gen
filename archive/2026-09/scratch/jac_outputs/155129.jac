import math;

"""Quantidade de digitos do fatorial de number."""
def kamenetsky(number: int) -> int {
    if number < 0 {
        return 0;
    } elif number <= 1 {
        return 1;
    }
    n = float(number);
    digits = n * math.log10(n / math.e) + math.log10(2.0 * math.pi * n) / 2.0;
    return math.floor(digits) + 1;
}