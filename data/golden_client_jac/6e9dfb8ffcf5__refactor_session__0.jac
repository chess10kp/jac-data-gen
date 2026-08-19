"""RL driver (synthetic): reverse the decimal digits of an integer, keeping sign."""

def reverse_int(n: int) -> int;

impl reverse_int {
    # >>>HOLE id="syn_reverse_int" instruction="Implement reverse_int(n): return n with its decimal digits reversed, preserving the sign (e.g. -456 -> -654, 100 -> 1). Remember whether n was negative, work with abs(n) by peeling off n % 10 into r = r * 10 + digit and integer-dividing by 10, then re-apply the negative sign."
    neg = n < 0;
    n = abs(n);
    r = 0;
    while n > 0 {
        r = r * 10 + n % 10;
        n = n // 10;
    }
    if neg {
        return -r;
    }
    return r;
    # <<<HOLE
}

with entry {
    for x in [123, 100, -456, 7, 0] {
        print(reverse_int(x));
    }
}
