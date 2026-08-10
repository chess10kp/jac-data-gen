"""
    Convers D to an integer in seconds
    Args:
        d (str): Duration
    Returns:
        int: Time in seconds of duration
    """
def proctime(d: Any) -> object {
    t = {"s": 1, "m": 60, "h": 3600, "d": 86400, "w": 604800};
    suffix = d[-1];
    d = int(d[:-1]);
    d = d * t[suffix];
    return d;
}