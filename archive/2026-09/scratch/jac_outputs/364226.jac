"""Validate integer values from a dictionary.

    Parameters
    ----------
    value : int
        Value to be validated.
    error_msg : str
        Error message for an invalid value.

    Returns
    -------
    int
        Validated value.

    Raises
    ------
    TypeError
        Raised when the value is not valid (namely, when it is data that cannot be cast to int).
    """
def __validate_integer_fields(value: int, error_msg: str) -> int {
    try {
        int_field = int(value);
        return int_field;
    } except ValueError {
        raise TypeError(error_msg);
    }
}