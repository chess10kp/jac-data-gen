"""
    overpython.subt(intf, ints)

    Subtract intf with ints. Raises ValueError if intf/ints is a string.
    """
def subt(intf: int | float | str, ints: int | float | str) -> float {
    try {
        return float(intf) - float(ints);
    } except ValueError {
        raise ValueError(("%s/%s is not a number" % (intf, ints)));
    }
}