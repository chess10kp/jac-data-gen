"""RL driver (synthetic): sign of an integer (-1, 0, or 1)."""

def sign(n: int) -> int;

impl sign {
    # >>>HOLE id="syn_sign" instruction="Implement sign(n): return 1 if n is positive, -1 if n is negative, and 0 if n is zero."
    if n > 0 {
        return 1;
    }
    if n < 0 {
        return -1;
    }
    return 0;
    # <<<HOLE
}

with entry {
    for x in [7, -4, 0, 100, -1] {
        print(sign(x));
    }
}
