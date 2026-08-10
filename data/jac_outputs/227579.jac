"""
returns pow(a,b) for integers

constructed in terms of lower arithmetic to be compatible
with cost calculations
"""
def ipow(a: int, b: int) -> int {
    if b == 0 {
        return 1;
    }
    if a == 0 {
        return 0;
    }
    if a == 1 {
        return 1;
    }
    if a == -1 {
        if b % 2 == 1 {
            return -1;
        }
        return 1;
    }
    if b < 0 {
        raise ValueError('ipow not defined for negative exponent and |base|>1');
    }
    val = 1;
    while True {
        bit = b % 2;
        b = b // 2;
        if bit {
            val = val * a;
        }
        if b == 0 {
            break;
        }
        a = a * a;
    }
    return val;
}