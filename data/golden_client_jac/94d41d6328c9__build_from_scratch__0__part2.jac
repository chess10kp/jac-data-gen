"""Axis-angle (Rodrigues) rotation matrix: degrees + (x,y,z) axis -> flat column-major 4x4. Normalizes the axis."""

import math;
glob Math = math;

def _m_rotate(ang: float, x: float, y: float, z: float) -> list {
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
}

with entry {
    m = _m_rotate(90.0, 0.0, 0.0, 1.0);
    for v in m {
        print(str(round(v, 6)));
    }
}
