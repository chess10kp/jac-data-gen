"""Squares

    Arguments:
        num {int} -- Upper bound for the list of squares to generate

    Returns:
        dict -- The squares dictionary
    """
def squares(num: Any) -> object {
    squares = {};
    if (num <= 0) {
        return squares;
    }
    for n in range(1, (num + 1)) {
        squares[n] = n * n;
    }
    return squares;
}