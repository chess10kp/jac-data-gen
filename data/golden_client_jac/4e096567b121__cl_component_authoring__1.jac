"""RL driver (numeric): raylib_shim._m_frustum (column-major perspective frustum matrix).

Origin: this_is_jac/raylib_shooter/web/raylib_shim.cl.jac (the _m_frustum logic,
isolated from io/time/graph/render machinery). Deterministic: pure +,-,*,/ arithmetic
on the six fixed frustum parameters, with no Math/GL/IO/time/random, so stdout is
byte-identical every run. The marked body is the unit the policy must regenerate; the
with entry block exercises it on fixed inputs and prints a deterministic projection
(floats rounded to 6 dp).
"""

def _m_frustum(l: float, r: float, b: float, t: float, n: float, f: float) -> list {
    # >>>HOLE id="lib_m_frustum" instruction="Return a column-major 4x4 perspective frustum matrix as a flat list of 16 floats from the left l, right r, bottom b, top t, near n, and far f planes. Position 0 is 2*n/(r-l); position 5 is 2*n/(t-b); position 8 is (r+l)/(r-l); position 9 is (t+b)/(t-b); position 10 is -(f+n)/(f-n); position 11 is -1.0; position 14 is -2*f*n/(f-n). All other positions are 0.0."
    return [
        2.0 * n / (r - l),
        0.0,
        0.0,
        0.0,
        0.0,
        2.0 * n / (t - b),
        0.0,
        0.0,
        (r + l) / (r - l),
        (t + b) / (t - b),
        -(f + n) / (f - n),
        -1.0,
        0.0,
        0.0,
        -2.0 * f * n / (f - n),
        0.0
    ];
    # <<<HOLE
}

with entry {
    res = _m_frustum(-1.0, 1.0, -1.0, 1.0, 1.0, 100.0);
    parts = [];
    for v in res {
        parts.append(str(round(v, 6)));
    }
    print(" ".join(parts));
}
