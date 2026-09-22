"""
    Convert the string data field *s* to a float. If the value is
    99999 (missing data) or 88888 (not observed), return not a number.
    """
def convert_float(s: str) -> float {
    f = float(s);
    if int(f) in (99999, 88888) {
        return float('nan');
    }
    return f;
}