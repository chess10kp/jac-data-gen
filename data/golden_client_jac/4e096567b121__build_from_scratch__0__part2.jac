def _m_frustum(l: float, r: float, b: float, t: float, n: float, f: float) -> list {
    return [
        2.0 * n / (r - l),
        0.0,
        0.0,
        0.0,
        0.0,
        2.0 * n / (t - b),
        0.0,
        0.0,
        (r + l) / (r - l),
        (t + b) / (t - b),
        -(f + n) / (f - n),
        -1.0,
        0.0,
        0.0,
        -2.0 * f * n / (f - n),
        0.0
    ];
}

with entry {
    res = _m_frustum(-1.0, 1.0, -1.0, 1.0, 1.0, 100.0);
    parts = [];
    for v in res {
        parts.append(str(round(v, 6)));
    }
    print(" ".join(parts));
}
