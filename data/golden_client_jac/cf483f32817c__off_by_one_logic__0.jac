"""RL driver (pure-lib): raylib_shim._m_translate (column-major 4x4 translation matrix).

Origin: this_is_jac/raylib_shooter/web/raylib_shim.cl.jac (the _m_translate logic,
isolated from io/time/graph/render machinery). The _m_ident helper it needs is inlined
outside the hole. Deterministic: pure list construction plus three assignments on fixed
inputs, with no Math/GL/IO/time/random, so stdout is byte-identical every run. The marked
body is the unit the policy must regenerate; the with entry block exercises it on fixed
inputs and prints a deterministic projection (floats rounded to 6 dp).
"""

def _m_ident() -> list {
    return [
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0
    ];
}

def _m_translate(x: float, y: float, z: float) -> list {
    # >>>HOLE id="lib_m_translate" instruction="Build a column-major 4x4 translation matrix for the offset (x, y, z). Start from the identity matrix returned by _m_ident(), then set element 12 to x, element 13 to y, and element 14 to z. Return the matrix."
    m = _m_ident();
    m[12] = x;
    m[13] = y;
    m[14] = z;
    return m;
    # <<<HOLE
}

with entry {
    res = _m_translate(2.0, -3.0, 5.0);
    parts = [];
    for v in res {
        parts.append(str(round(v, 6)));
    }
    print(" ".join(parts));
}
