"""Seeded-LCG uniform RNG: rand01() in [0,1) and rand_range(lo, hi) scaled into [lo, hi)."""

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
