"""RL driver (numeric): raylib_shim._m_rotate (axis-angle Rodrigues 4x4 rotation matrix).

Origin: this_is_jac/raylib_shim.cl.jac (the _m_rotate helper, isolated from io/time/graph/render
machinery). Deterministic: Math is aliased to Python's math module outside the hole, so cos/sin/hypot
are pure functions of fixed args; all printed floats are rounded. The marked body is the unit the
policy must regenerate; the with entry block exercises it on fixed inputs and prints a deterministic
projection.
"""

import math;
glob Math = math;

def _m_rotate(ang: float, x: float, y: float, z: float) -> list {
    # >>>HOLE id="lib_m_rotate" instruction="Build a column-major flat 4x4 rotation matrix for angle ang (in degrees) about axis (x, y, z). Convert ang to radians a by multiplying by pi/180. Compute c = cos(a), s = sin(a), and ln = hypot(x, y, z); if ln is zero set ln to 1.0. Normalize the axis by dividing x, y, z by ln. Let t = 1 - c. Return the 16-element Rodrigues rotation matrix using these normalized components and c, s, t (the standard axis-angle rotation matrix), with the last column and row being identity-like (0,0,0,1)."
    a = ang * 3.141592653589793 / 180.0;
    c = Math.cos(a);
    s = Math.sin(a);
    ln = Math.hypot(x, y, z);
    if ln == 0.0 {
        ln = 1.0;
    }
    x = x / ln;
    y = y / ln;
    z = z / ln;
    t = 1.0 - c;
    return [
        x * x * t + c,
        y * x * t + z * s,
        x * z * t - y * s,
        0.0,
        x * y * t - z * s,
        y * y * t + c,
        y * z * t + x * s,
        0.0,
        x * z * t + y * s,
        y * z * t - x * s,
        z * z * t + c,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0
    ];
    # <<<HOLE
}

with entry {
    m = _m_rotate(90.0, 0.0, 0.0, 1.0);
    for v in m {
        print(str(round(v, 6)));
    }
}
