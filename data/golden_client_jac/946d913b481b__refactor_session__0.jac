"""RL driver (synthetic): clamp an integer into the inclusive range [lo, hi]."""

def clamp(x: int, lo: int, hi: int) -> int;

impl clamp {
    # >>>HOLE id="syn_clamp" instruction="Implement clamp(x, lo, hi): return lo if x is below lo, hi if x is above hi, otherwise x itself."
    if x < lo {
        return lo;
    }
    if x > hi {
        return hi;
    }
    return x;
    # <<<HOLE
}

with entry {
    print(clamp(5, 0, 10));
    print(clamp(-3, 0, 10));
    print(clamp(15, 0, 10));
    print(clamp(0, 0, 10));
    print(clamp(10, 0, 10));
}
