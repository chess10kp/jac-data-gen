"""
    returns true if token is a number
    """
def is_number(s: Any) -> object {
    try {
        float(s) if ('.' in s) else int(s);
        return True;
    } except ValueError {
        return False;
    }
}