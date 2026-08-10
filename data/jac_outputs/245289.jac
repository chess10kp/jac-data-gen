"""Convert degrees into arc units (degrees, minutes, seconds) and sign."""
def degToDMS(g: float) -> tuple[int, int, float, int] {
    sign = 1;
    if g < 0.0 {
        sign = -1;
    }
    g = abs(g);
    d = int(g) * sign;
    g = g - int(g);
    m = int(g * 60.0);
    g = g - m / 60.0;
    s = g * 3600.0;
    return (d, m, s, sign);
}