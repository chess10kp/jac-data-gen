"""Conversions between RGB and the YIQ, HLS and HSV color systems.

All coordinates are floats in [0, 1] (I and Q of YIQ may be negative).
Ported from CPython's colorsys module.
"""

glob ONE_THIRD: float = 1.0 / 3.0,
     ONE_SIXTH: float = 1.0 / 6.0,
     TWO_THIRD: float = 2.0 / 3.0;

def _clamp(x: float) -> float {
    return min(max(x, 0.0), 1.0);
}

"""YIQ uses the FCC NTSC constants."""
def rgb_to_yiq(r: float, g: float, b: float) -> tuple[float, float, float] {
    y = 0.30 * r + 0.59 * g + 0.11 * b;
    i = 0.74 * (r - y) - 0.27 * (b - y);
    q = 0.48 * (r - y) + 0.41 * (b - y);
    return (y, i, q);
}

def yiq_to_rgb(y: float, i: float, q: float) -> tuple[float, float, float] {
    r = y + 0.9468822170900693 * i + 0.6235565819861433 * q;
    g = y - 0.27478764629897834 * i - 0.6356910791873801 * q;
    b = y - 1.1085450346420322 * i + 1.7090069284064666 * q;
    return (_clamp(r), _clamp(g), _clamp(b));
}

def _hue(r: float, g: float, b: float, maxc: float, rangec: float) -> float {
    rc = (maxc - r) / rangec;
    gc = (maxc - g) / rangec;
    bc = (maxc - b) / rangec;
    h: float = 0.0;
    if r == maxc {
        h = bc - gc;
    } elif g == maxc {
        h = 2.0 + rc - bc;
    } else {
        h = 4.0 + gc - rc;
    }
    return (h / 6.0) % 1.0;
}

def rgb_to_hls(r: float, g: float, b: float) -> tuple[float, float, float] {
    maxc = max(r, g, b);
    minc = min(r, g, b);
    sumc = maxc + minc;
    rangec = maxc - minc;
    l = sumc / 2.0;
    if minc == maxc {
        return (0.0, l, 0.0);
    }
    # Not always 2.0 - sumc: gh-106498.
    s = rangec / sumc if l <= 0.5 else rangec / (2.0 - maxc - minc);
    return (_hue(r, g, b, maxc, rangec), l, s);
}

def _v(m1: float, m2: float, hue: float) -> float {
    hue = hue % 1.0;
    if hue < ONE_SIXTH {
        return m1 + (m2 - m1) * hue * 6.0;
    }
    if hue < 0.5 {
        return m2;
    }
    if hue < TWO_THIRD {
        return m1 + (m2 - m1) * (TWO_THIRD - hue) * 6.0;
    }
    return m1;
}

def hls_to_rgb(h: float, l: float, s: float) -> tuple[float, float, float] {
    if s == 0.0 {
        return (l, l, l);
    }
    m2 = l * (1.0 + s) if l <= 0.5 else l + s - (l * s);
    m1 = 2.0 * l - m2;
    return (_v(m1, m2, h + ONE_THIRD), _v(m1, m2, h), _v(m1, m2, h - ONE_THIRD));
}

def rgb_to_hsv(r: float, g: float, b: float) -> tuple[float, float, float] {
    maxc = max(r, g, b);
    minc = min(r, g, b);
    rangec = maxc - minc;
    if minc == maxc {
        return (0.0, 0.0, maxc);
    }
    return (_hue(r, g, b, maxc, rangec), rangec / maxc, maxc);
}

def hsv_to_rgb(h: float, s: float, v: float) -> tuple[float, float, float] {
    if s == 0.0 {
        return (v, v, v);
    }
    i = int(h * 6.0);
    f = (h * 6.0) - i;
    p = v * (1.0 - s);
    q = v * (1.0 - s * f);
    t = v * (1.0 - s * (1.0 - f));
    match i % 6 {
        case 0: return (v, t, p);
        case 1: return (q, v, p);
        case 2: return (p, v, t);
        case 3: return (p, q, v);
        case 4: return (t, p, v);
        case _: return (v, p, q);
    }
}
