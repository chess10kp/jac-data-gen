"""
    Get a given value's percent in the range.
    :param value: value
    :param minimum: the range's minimum value
    :param maximum: the range's maximum value
    :return: percent float
    """
def get_percent(value: Any, minimum: Any, maximum: Any) -> object {
    if (minimum == maximum) {
        return 100;
    }
    return max(0, min(100, (((value - minimum) * 100) / (maximum - minimum))));
}