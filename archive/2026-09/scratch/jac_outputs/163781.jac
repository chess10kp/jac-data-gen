"""
    checks if a string is ascii
    """
def is_ascii(s: Any) -> object {
    try {
        s.encode("ascii");
        return True;
    } except UnicodeEncodeError {
        return False;
    }
}