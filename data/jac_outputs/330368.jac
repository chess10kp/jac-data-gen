"""
    return the smallest possible data type for a string or list of strings

    x: str or list
        a string to be parsed
    Returns int, float or str
        the parsing result

    Examples
    --------
    >>> isinstance(parse_literal('1.5'), float)
    >>> isinstance(parse_literal('1'), int)
    >>> isinstance(parse_literal('foobar'), str)
    """
def parse_literal(x: Any) -> object {
    if isinstance(x, list) {
        return [parse_literal(y) for y in x];
    } elif isinstance(x, (bytes, str)) {
        try {
            return int(x);
        } except ValueError {
            try {
                return float(x);
            } except ValueError {
                return x;
            }
        }
    } else {
        raise TypeError('input must be a string or a list of strings');
    }
}