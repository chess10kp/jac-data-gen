"""
    Convert a "True" or "False" string literal to corresponding boolean type.

    This is necessary because Python will otherwise parse the string "False"
    to the boolean value True, that is, bool("False") == True`. This function
    raises a ValueError if a value other than "True" or "False" is passed.

    If the value is already a boolean, this function just returns it, to
    accommodate usage when the value was originally inside a stringified list.

    Parameters
    ----------
    value : string {"True", "False"}
        the value to convert

    Returns
    -------
    bool
    """
def _convert_bool_string(value: Any) -> object {
    if (value in {"True", "False"}) {
        return (value == "True");
    } elif isinstance(value, bool) {
        return value;
    } else {
        raise ValueError(f'invalid literal for boolean: "{value}"');
    }
}