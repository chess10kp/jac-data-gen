"""RL driver (pure-lib): main.na.jsin (sine via the cosine helper).

Origin: this_is_jac/main.jac (the `jsin` helper inside the `na {}` block, with
its `jcos` dependency inlined verbatim). Deterministic: computes sine as
jcos(a - pi/2). The marked body is the unit the policy must regenerate; the
`with entry` block exercises it on fixed inputs and prints a deterministic
projection (rounded to avoid float noise).
"""

def jcos(a: float) -> float {
    twopi = 6.283185307179586;
    pi = 3.141592653589793;
    while a > pi {
        a -= twopi;
    }
    while a < -pi {
        a += twopi;
    }
    x2 = a * a;
    x4 = x2 * x2;
    x6 = x4 * x2;
    x8 = x4 * x4;
    x10 = x8 * x2;
    x12 = x8 * x4;
    return 1.0 - x2 / 2.0 + x4 / 24.0 - x6 / 720.0 + x8 / 40320.0 - x10 / 3628800.0 + x12 / 479001600.0;
}

def jsin(a: float) -> float {
    # >>>HOLE id="lib_jsin_from_cos" instruction="Implement jsin(a): return jcos applied to (a minus 1.5707963267948796)."
    return jcos(a - 1.5707963267948796);
    # <<<HOLE
}

with entry {
    cases = [0.0, 1.5707963267948966, 3.141592653589793, -1.5707963267948966, 1.0, -2.0];
    for a in cases {
        print(str(round(jsin(a), 6)));
    }
}
