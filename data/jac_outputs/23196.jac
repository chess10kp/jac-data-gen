"""
    This method simply checks to see if the user supplied value has delimiters.
    That is, if it starts and ends with double-quotes, then it is delimited.
    """
def isDelimited(value: Any) -> object {
    if (len(value) < 2) {
        return False;
    }
    if ((value[0] == '"') and (value[-1] == '"')) {
        return True;
    } else {
        return False;
    }
}