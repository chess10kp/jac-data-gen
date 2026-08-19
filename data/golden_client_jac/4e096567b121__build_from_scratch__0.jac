def _m_frustum(l: float, r: float, b: float, t: float, n: float, f: float) -> list {
    return [
        2.0*n/(r-l), 0.0, (r+l)/(r-l), 0.0,
        0.0, 2.0*n/(t-b), (t+b)/(t-b), 0.0,
        0.0, 0.0, -(f+n)/(f-n), -2.0*f*n/(f-n),
        0.0, 0.0, -1.0, 0.0
    ];
}
