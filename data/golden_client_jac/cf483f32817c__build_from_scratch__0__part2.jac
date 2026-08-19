"""Column-major 4x4 translation matrix built from the identity helper."""

def _m_ident() -> list {
    return [
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0
    ];
}

def _m_translate(x: float, y: float, z: float) -> list {
    m = _m_ident();
    m[12] = x;
    m[13] = y;
    m[14] = z;
    return m;
}

with entry {
    res = _m_translate(2.0, -3.0, 5.0);
    parts = [];
    for v in res {
        parts.append(str(round(v, 6)));
    }
    print(" ".join(parts));
}
