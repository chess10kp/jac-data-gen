"""Finds close elements in two arrays with diffrent sizes.

    Parameters
    ----------
    a : array of floats with dimention of N
        Description of parameter `a`.
    b : array of floats with dimention of M
        Description of parameter `b`.
    precision : threshold withing which two elements are considered the same.
        Description of parameter `precision`.

    Returns
    -------
    [array, array]
        returns two arrays with the elements that mathched withing the
        precision.
    """
def find_close_elements(a: Any, b: Any, precision: Any = 0.01) -> object {
    return [
        [
            x for x in a
            for i in b
            if (abs((x - i)) < precision)
        ],
        [
            x for x in b
            for i in a
            if (abs((x - i)) < precision)
        ]
    ];
}