"""
    Convert degrees, minutes, seconds, quadrant to decimal degrees

    :param degrees: coordinate degrees
    :type degrees: int
    :param minutes: coordinate minutes
    :type minutes: int
    :param seconds: coordinate seconds
    :type seconds: int
    :param quadrant: coordinate quadrant (N, E, S, W)
    :type quadrant: str|unicode

    :return: decimal degrees
    :rtype: float
    """
def dms2dd(degrees: Any, minutes: Any, seconds: Any, quadrant: Any) -> object {
    illegal_vals = (None, '', '');
    for iv in illegal_vals {
        if (iv in (degrees, minutes, seconds, quadrant)) {
            raise ValueError(("ERROR: Illegal value: %s" % iv));
        }
    }
    if (quadrant.lower() not in ('n', 'e', 's', 'w')) {
        raise ValueError(("ERROR: Invalid quadrant: %s" % quadrant));
    }
    output = int(degrees) + (int(minutes) / 60) + (int(seconds) / 3600);
    if (quadrant.lower() in ('s', 'w')) {
        output *= -1;
    }
    return output;
}