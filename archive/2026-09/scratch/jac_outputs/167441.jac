"""
    min : integer
    max: integer
    value : value element DOM. Example : document['id].value
    message_error : str message
    message_valid: str message
    function return tuple
    """
def lenght(
    value: str,
    min: int | None,
    max: int | None,
    message_error: str | None = None,
    message_valid: str | None = None
) -> tuple[bool, str, str] {
    if min is not None and len(value) < min {
        return (False, message_error or ('length of value must be at least %s' % min), value);
    }
    if max is not None and len(value) > max {
        return (False, message_error or ('length of value must be at most %s' % min), value);
    }
    return (True, message_valid or 'valid', value);
}