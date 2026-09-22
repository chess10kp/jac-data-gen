"""
    Detect whether obj is a SEA object.

    :param obj: Object

    """
def isSea(`obj: Any) -> object {
    return True if hasattr(`obj, 'SeaObject') else False;
}