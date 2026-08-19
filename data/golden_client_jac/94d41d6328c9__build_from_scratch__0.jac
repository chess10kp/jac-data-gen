import math;
glob Math = math;

def _m_rotate(ang: float, x: float, y: float, z: float) -> list {
    a = ang * 3.141592653589793 / 180.0;
    c = Math.cos(a);
    s = Math.sin(a);
    t = 1.0 - c;
    return [
        x * x * t + c, y * x * t + z * s, x * z * t - y * s, 0.0,
        x * y * t - z * s, y * y * t + c, y * z * t + x * s, 0.0,
        x * z * t + y * s, y * z * t - x * s, z * z * t + c, 0.0,
        0.0, 0.0, 0.0, 1.0
    ];
}
