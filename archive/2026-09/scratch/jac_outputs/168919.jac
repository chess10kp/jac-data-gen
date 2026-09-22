"""
    return max value by deviation from 0

    :param lst iterable: list of values to find max in
    :returns: max value by deviation from 0
    """
def amax(lst: list[float]) -> float {
    return max([abs(x) for x in lst]);
}