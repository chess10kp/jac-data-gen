import unicodedata;

"""    is_number(s)

    Try what you passed if is a number value.

    Parameters
    ----------
    s : Object
        Value you want to try if is a number.
    Returns
    -------
    Boolean
    Return if is a number.
    """
def is_number(s: str | int | float | bool) -> bool {
    try {
        float(s);
        return True;
    } except ValueError {
        ;
    }
    try {
        unicodedata.numeric(s as str);
        return True;
    } except (TypeError, ValueError) {
        ;
    }
    return False;
}