"""
    Test if a symbol or label is defined.

    :param s: The symbol to look up.
    :param table: A dictionary containing the labels and symbols.
    :return: True if defined, False otherwise.
    """
def is_defined(s: Any, table: Any) -> object {
    try {
        table[s];
        return True;
    } except KeyError {
        return False;
    }
}