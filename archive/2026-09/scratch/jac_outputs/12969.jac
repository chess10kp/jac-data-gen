"""Convert number of seconds to the string ``mm:ss``.

    Note: If the number of minutes is greater than 100, it will
    be displayed as such.

    Args:
        secs (int): Number of seconds.

    Returns
        str: String in the format of ``mm:ss``.
    """
def secondsToMMSS(secs: Any) -> object {
    secs = int(secs);
    (minutes, seconds) = divmod(secs, 60);
    return '{:02d}:{:02d}'.format(minutes, seconds);
}