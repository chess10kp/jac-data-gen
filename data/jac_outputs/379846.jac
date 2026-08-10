"""
    Determines if a string can be converted to a number.
    """
def my_isnumeric(value: str) -> bool {
    try {
        float(value);
    } except ValueError {
        return False;
    }
    return True;
}