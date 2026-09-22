"""Convert pitch string to meters.

    Something like -600- is assumed to mean "six-hundreths of an inch".

    >>> _pitch2m("-600-")
    4.233333333333333e-05
    >>> _pitch2m("-1200-")
    2.1166666666666665e-05
    """
def _pitch2m(res: Any) -> object {
    res = int(res[1:-1]);
    return (0.0254 / res);
}