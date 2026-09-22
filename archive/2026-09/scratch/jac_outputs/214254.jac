"""
    Converts the integer n to a padded string with leading zeros
    """
def convertImageIDToPaddedString(n: Any, numCharacters: Any = 10) -> object {
    t = str(n);
    return t.rjust(numCharacters, '0');
}