"""RL driver (synthetic): greatest common divisor of two integers (Euclid)."""

def gcd(a: int, b: int) -> int;

impl gcd {
    # >>>HOLE id="syn_gcd" instruction="Implement gcd(a, b): return the greatest common divisor of a and b using the Euclidean algorithm — while b is not zero, set t = b, then b = a % b, then a = t; finally return abs(a)."
    while b != 0 {
        t = b;
        b = a % b;
        a = t;
    }
    return abs(a);
    # <<<HOLE
}

with entry {
    print(gcd(48, 36));
    print(gcd(17, 5));
    print(gcd(100, 75));
    print(gcd(0, 9));
    print(gcd(42, 56));
}
