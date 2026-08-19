"""RL driver (pure-lib): raylib_shim._m_ident (column-major 4x4 identity matrix).

Origin: this_is_jac/raylib_shooter/web/raylib_shim.cl.jac (the _m_ident logic,
isolated from io/time/graph/render machinery). Deterministic: the body is a fixed
literal 16-float list with no inputs, Math/GL, or IO, so stdout is byte-identical
every run. The marked body is the unit the policy must regenerate; the with entry
block exercises it on fixed inputs and prints a deterministic projection.
"""

def _m_ident() -> list {
    # >>>HOLE id="lib_m_ident" instruction="Return the column-major 4x4 identity matrix as a flat list of 16 floats. The diagonal entries (positions 0, 5, 10, and 15) are 1.0 and every other position is 0.0."
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
    # <<<HOLE
}

with entry {
    print(str(_m_ident()));
}
