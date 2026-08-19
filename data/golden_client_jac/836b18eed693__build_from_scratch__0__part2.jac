"""Column-major 4x4 orthographic projection matrix from l/r/b/t/n/f planes, GL-style depth."""

def _m_ortho(l: float, r: float, b: float, t: float, n: float, f: float) -> list {
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
}

with entry {
    res = _m_ortho(0.0, 960.0, 600.0, 0.0, -1.0, 1.0);
    parts = [];
    for v in res {
        parts.append(str(round(v, 6)));
    }
    print(" ".join(parts));
}
