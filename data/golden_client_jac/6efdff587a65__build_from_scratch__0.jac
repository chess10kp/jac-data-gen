def _m_mul(a: list, b: list) -> list {
    c = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    row = 0;
    while row < 4 {
        col = 0;
        while col < 4 {
            s = 0.0;
            k = 0;
            while k < 4 {
                s = s + a[row * 4 + k] * b[k * 4 + col];
                k = k + 1;
            }
            c[row * 4 + col] = s;
            col = col + 1;
        }
        row = row + 1;
    }
    return c;
}
