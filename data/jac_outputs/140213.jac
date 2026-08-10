"""Whether the given object is iterable or not.

    This is tested simply by invoking ``iter(obj)`` and returning ``False`` if
    this operation raises a TypeError.

    Args:
        obj: The object to test

    Returns:
        bool: True if iterable, False else
    """
def is_iterable(`obj: Any) -> bool {
    try {
        iter(`obj);
    } except TypeError {
        return False;
    }
    return True;
}