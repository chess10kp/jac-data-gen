"""RL driver (pure-lib): main.na.jcos (range-reduced Taylor cosine).

Origin: this_is_jac/main.jac (the `jcos` helper inside the `na {}` block).
Deterministic: reduces the angle into [-pi, pi] by adding/subtracting 2*pi, then
evaluates a 7-term Taylor series for cosine. The marked body is the unit the
policy must regenerate; the `with entry` block exercises it on fixed inputs and
prints a deterministic projection (rounded to avoid float noise).
"""

def jcos(a: float) -> float {
    # >>>HOLE id="lib_jcos_taylor" instruction="Implement jcos(a): a range-reduced Taylor-series cosine. Set twopi to 6.283185307179586 and pi to 3.141592653589793. While a is greater than pi, subtract twopi from a; while a is less than negative pi, add twopi to a. Then let x2 = a*a, x4 = x2*x2, x6 = x4*x2, x8 = x4*x4, x10 = x8*x2, x12 = x8*x4. Return 1.0 minus x2/2.0 plus x4/24.0 minus x6/720.0 plus x8/40320.0 minus x10/3628800.0 plus x12/479001600.0."
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
    # <<<HOLE
}

with entry {
    cases = [0.0, 1.5707963267948966, 3.141592653589793, -3.141592653589793, 6.283185307179586, 1.0, -2.0];
    for a in cases {
        print(str(round(jcos(a), 6)));
    }
}
