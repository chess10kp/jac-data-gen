"""Returns True if str s is entirely ASCII characters.

    (Compare to Python 3.7 `str.isascii()`.)
    """
def isascii(s: Any) -> object {
    try {
        s.encode("ascii");
    } except UnicodeEncodeError {
        return False;
    }
    return True;
}