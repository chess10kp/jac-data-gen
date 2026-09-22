"""Convert degrees into hex coordinates."""
def deg2dms(val: float, delim: str = ':') -> str {
    sign = -1 if val < 0 else 1;
    d = int(sign * val);
    m = int((sign * val - d) * 60.0);
    s = ((sign * val - d) * 60.0 - m) * 60.0;
    return '{}{}{}{}{}'.format(sign * d, delim, m, delim, s);
}