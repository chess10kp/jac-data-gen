"""Multiply two column-major 4x4 matrices (flat lists of 16 floats) into a flat list of 16 floats."""

def _m_mul(a: list, b: list) -> list {
    c = [
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0
    ];
    col = 0;
    while col < 4 {
        row = 0;
        while row < 4 {
            s = 0.0;
            k = 0;
            while k < 4 {
                s = s + a[row + 4 * k] * b[k + 4 * col];
                k = k + 1;
            }
            c[row + 4 * col] = s;
            row = row + 1;
        }
        col = col + 1;
    }
    return c;
}

with entry {
    # a: translate by (2,3,4); b: scale by 2 (both column-major).
    a = [
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        2.0, 3.0, 4.0, 1.0
    ];
    b = [
        2.0, 0.0, 0.0, 0.0,
        0.0, 2.0, 0.0, 0.0,
        0.0, 0.0, 2.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    ];
    res = _m_mul(a, b);
    parts = [];
    for v in res {
        parts.append(str(round(v, 6)));
    }
    print(" ".join(parts));
}
