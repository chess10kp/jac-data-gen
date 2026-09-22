"""Throw an exception if the value is not on the unit interval [0,1].
    """
def verify_unit_interval(value: Any) -> object {
    if not ((value >= 0) and (value <= 1)) {
        raise ValueError("expected value on the interval [0, 1].");
    }
    return value;
}