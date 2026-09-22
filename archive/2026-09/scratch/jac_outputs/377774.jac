"""Accept a step when using the doubling procedure (Neal 2003)."""
def slice_double_accept(
    xp: float,
    x: float,
    u: float,
    step: float,
    interval: tuple[float, float],
    lnpdf: callable[[float], float],
    pdf_params: tuple[float, ...]
) -> bool {
    (xl, xr) = interval;
    d = False;
    acceptable = True;
    while (xr - xl) > 1.1 * step {
        m = (xl + xr) * 0.5;
        if (x < m and xp >= m) or (x >= m and xp < m) {
            d = True;
        }
        if xp < m {
            xr = m;
        } else {
            xl = m;
        }
        if d and lnpdf(xl, *pdf_params) <= u and lnpdf(xr, *pdf_params) <= u {
            acceptable = False;
            break;
        }
    }
    return acceptable;
}