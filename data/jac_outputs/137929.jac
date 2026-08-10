"""
    Extend the given list with the given element. If element is a scalar, it is
    appended to target; if element is a list, target is extended with it.
    >>> extend([1, 2], 4)
    [1, 2, 4]
    >>> extend([1, 2], (1, 2,))
    [1, 2, 1, 2]
    >>> extend([1, 2], {1: 2, 3: 4})
    [1, 2, {1: 2, 3: 4}]
    >>> extend([1, 2], [0, 1])
    [1, 2, 0, 1]

    :param target:
    :type target: list
    :param element:
    :rtype: list

    """
def extend(target: list[object], element: object) -> list[object] {
    assert isinstance(target, list);
    if isinstance(element, (list, tuple)) {
        target.extend(element);
    } else {
        target.append(element);
    }
    return target;
}