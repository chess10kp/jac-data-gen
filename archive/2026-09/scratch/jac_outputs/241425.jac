"""Validation function constrains minimal and maximal lengths of string."""
def constrain_string(string: str, minlen: int, maxlen: int) -> str {
    if len(string) < minlen {
        raise ValueError('Input need to be at least %s characters long' % minlen);
    } elif len(string) > maxlen {
        raise ValueError('Input need to be maximum %s characters long' % maxlen);
    }
    return string;
}