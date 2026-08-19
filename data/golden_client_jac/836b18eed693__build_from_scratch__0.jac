def _m_ortho(l: float, r: float, b: float, t: float, n: float, f: float) -> list {
    return [
        2.0 / (r - l), 0.0, 0.0, 0.0,
        0.0, 2.0 / (t - b), 0.0, 0.0,
        0.0, 0.0, -2.0 / (f - n), 0.0,
        -(r + l) / (r - l), -(t + b) / (t - b), -(f + n) / (f - n), 1.0
    ];
}
