"""
       blending function increasing concave
       d = delta x = xabs - xdr
       u = uncertainty radius of xabs estimate error
       s = tuning scale factor

       eq 3.12

       returns blend
    """
def blendConcaveInc(d: float = 0.0, u: float = 1.0, s: float = 1.0, h: float = 1.0) -> float {
    d = float(d);
    u = float(u);
    s = float(s);
    m = 2 * s - u - d;
    if m == 0 {
        return h;
    }
    if d >= s {
        return h;
    }
    b = h * (s - u) / m;
    return b;
}