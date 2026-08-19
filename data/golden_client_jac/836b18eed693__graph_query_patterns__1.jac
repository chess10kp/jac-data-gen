"""RL driver (numeric): raylib_shim._m_ortho (column-major orthographic matrix).

Origin: this_is_jac/raylib_shooter/web/raylib_shim.cl.jac (the _m_ortho logic,
isolated from io/time/graph/render machinery). Deterministic: pure +,-,*,/ arithmetic
on the six fixed ortho parameters, with no Math/GL/IO/time/random, so stdout is
byte-identical every run. The marked body is the unit the policy must regenerate; the
with entry block exercises it on fixed inputs and prints a deterministic projection
(floats rounded to 6 dp).
"""

def _m_ortho(l: float, r: float, b: float, t: float, n: float, f: float) -> list {
    # >>>HOLE id="lib_m_ortho" instruction="Return a column-major 4x4 orthographic projection matrix as a flat list of 16 floats from the left l, right r, bottom b, top t, near n, and far f planes. Position 0 is 2/(r-l); position 5 is 2/(t-b); position 10 is -2/(f-n); position 12 is -(r+l)/(r-l); position 13 is -(t+b)/(t-b); position 14 is -(f+n)/(f-n); position 15 is 1.0. All other positions are 0.0."
    return [
        2.0 / (r - l),
        0.0,
        0.0,
        0.0,
        0.0,
        2.0 / (t - b),
        0.0,
        0.0,
        0.0,
        0.0,
        -2.0 / (f - n),
        0.0,
        -(r + l) / (r - l),
        -(t + b) / (t - b),
        -(f + n) / (f - n),
        1.0
    ];
    # <<<HOLE
}

with entry {
    res = _m_ortho(0.0, 960.0, 600.0, 0.0, -1.0, 1.0);
    parts = [];
    for v in res {
        parts.append(str(round(v, 6)));
    }
    print(" ".join(parts));
}
