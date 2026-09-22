"""
    rounds to nearest 0.005 and makes it pretty (avoids floating point 0.000001 nonsense)
    """
def round_to_005(x: Any) -> object {
    res = round((x * 200)) / 200;
    return float(('%.3f' % res));
}