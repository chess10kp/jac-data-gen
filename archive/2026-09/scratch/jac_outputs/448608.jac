"""
Convert HSV to RGB (based on colorsys.py).

Args:
    h: Hue 0 to 1.
    s: Saturation 0 to 1.
    v: Value 0 to 1 (Brightness).
"""
def hsv_to_rgb(h: float, s: float, v: float) -> tuple[float | int, float | int, float | int] {
    if s == 0.0 {
        return (v, v, v);
    }
    i = int(h * 6.0);
    f = h * 6.0 - i;
    p = v * (1.0 - s);
    q = v * (1.0 - s * f);
    t = v * (1.0 - s * (1.0 - f));
    i = i % 6;
    v = int(v * 255);
    t = int(t * 255);
    p = int(p * 255);
    q = int(q * 255);
    match i {
        case 0:
            return (v, t, p);
        case 1:
            return (q, v, p);
        case 2:
            return (p, v, t);
        case 3:
            return (p, q, v);
        case 4:
            return (t, p, v);
        case 5:
            return (v, p, q);
    }
}