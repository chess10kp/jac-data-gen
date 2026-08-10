"""Returns the first true value in the iterable.

    If no true value is found, returns *default*

    If *pred* is not None, returns the first item
    for which pred(item) is true.

    """
def first_true(iterable: list[bool], `default: bool = False, pred: None = None) -> bool {
    return next(filter(pred, iterable), `default);
}