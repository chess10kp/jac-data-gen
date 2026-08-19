"""Column-major 4x4 identity matrix, stored as a flat list of 16 floats."""

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

with entry {
    print(str(_m_ident()));
}
