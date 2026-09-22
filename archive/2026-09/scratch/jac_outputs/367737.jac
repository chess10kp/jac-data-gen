"""Detects if string is integer, float or string.

    Parameters
    ----------
    string : string
        An input string to be tested.

    Returns
    -------
    string
        A string with value 'int' if input is an integer,
        'float' if the input is a float and 'string' if it
        is just a regular string.

    """
def test_string_content(string: Any) -> object {
    try {
        float(string);
        return 'int'
            if (
                (string.count('.') == 0) and ('e' not in string) and ('E' not in string)
            )
            else 'float';
    } except ValueError {
        return 'string';
    }
}