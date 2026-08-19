"""RL driver (numeric): raylib_shim._m_mul (column-major 4x4 matrix multiply).

Origin: this_is_jac/raylib_shooter/web/raylib_shim.cl.jac (the _m_mul logic,
isolated from io/time/graph/render machinery). Deterministic: the triple while-loop
column-major indexing is pure float arithmetic on two fixed input matrices, with no
Math/GL/IO/time/random, so stdout is byte-identical every run. The marked body is the
unit the policy must regenerate; the with entry block exercises it on fixed inputs and
prints a deterministic projection (floats rounded to 6 dp).
"""

def _m_mul(a: list, b: list) -> list {
    c = [
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0
    ];
    col = 0;
    while col < 4 {
        row = 0;
        while row < 4 {
            s = 0.0;
            k = 0;
            while k < 4 {
                s = s + a[row + 4 * k] * b[k + 4 * col];
                k = k + 1;
            }
            c[row + 4 * col] = s;
            row = row + 1;
        }
        col = col + 1;
    }
    return c;
}

with entry {
    # a: translate by (2,3,4); b: scale by 2 (both column-major).
    a = [
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        2.0, 3.0, 4.0, 1.0
    ];
    b = [
        2.0, 0.0, 0.0, 0.0,
        0.0, 2.0, 0.0, 0.0,
        0.0, 0.0, 2.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    ];
    res = _m_mul(a, b);
    parts = [];
    for v in res {
        parts.append(str(round(v, 6)));
    }
    print(" ".join(parts));
}
