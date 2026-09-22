"""
    Returns True if string 's' is integer and False if not.
    's' MUST be a string.
    """
def is_int(s: str) -> bool {
    try {
        int(s);
        return True;
    } except ValueError {
        return False;
    }
}