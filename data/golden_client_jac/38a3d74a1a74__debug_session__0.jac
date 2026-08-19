"""RL driver (pure-lib): main.na.rand01 (31-bit LCG step).

Origin: this_is_jac/main.jac (the `rand01` pseudo-random helper inside the
`na {}` block, with its module-level `rng` seed inlined verbatim). Deterministic
because the LCG is seeded from a fixed glob and advanced a fixed number of times:
each step updates rng = (rng * 1103515245 + 12345) mod 2147483648 and returns
rng / 2147483648.0. The marked body is the unit the policy must regenerate; the
`with entry` block exercises it on a fixed seed and prints a deterministic
projection (rounded to avoid float noise).
"""

glob rng: int = 987654321;

def rand01 -> float {
    global rng;
    rng = (rng * 1103515245 + 12345) % 2147483648;
    return float(rng) / 2147483648.0;
}

with entry {
    for _i in range(6) {
        print(str(round(rand01(), 9)));
    }
}
