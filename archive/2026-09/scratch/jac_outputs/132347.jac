"""
    Helper function that returns True if the provided value is an integer.
    """
def is_integer(val: Any) -> object {
    try {
        int(val);
    } except ValueError {
        return False;
    }
    return True;
}