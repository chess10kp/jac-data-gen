"""
    Returns ``True`` if ``pred`` returns ``False`` for all the elements in
    the ``iterable`` range or if the range is empty, and ``False`` otherwise.

        >>> none_of(lambda x: x % 2 == 0, [1, 3, 5, 7])
        True

    :param pred: a predicate function to check a value from the iterable range
    :param iterable: an iterable range to check in
    :returns: ``True`` if all elements don't satfisfy ``pred``
    """
def none_of(pred: Any, iterable: Any) -> object {
    return all(not pred(i) for i in iterable);
}