"""RL driver (pure-lib): main.na.rand_range (LCG-backed uniform range).

Origin: this_is_jac/main.jac (the `rand_range` helper inside the `na {}` block,
with its `rand01` dependency and module-level `rng` seed inlined verbatim).
Deterministic because the underlying LCG is seeded from a fixed glob and advanced
a fixed number of times. The marked body is the unit the policy must regenerate;
the `with entry` block exercises it on a fixed seed and prints a deterministic
projection (rounded to avoid float noise).
"""

glob rng: int = 987654321;

def rand01 -> float {
    global rng;
    rng = (rng * 1103515245 + 12345) % 2147483648;
    return float(rng) / 2147483648.0;
}

def rand_range(lo: float, hi: float) -> float {
    return lo + rand01() * (hi - lo);
}

with entry {
    cases = [(-14.0, 14.0), (1.0, 5.0), (-16.0, 2.0), (0.0, 6.28)];
    for (lo, hi) in cases {
        print(str(round(rand_range(lo, hi), 6)));
    }
}
