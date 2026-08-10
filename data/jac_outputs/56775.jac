"""Return True if 'c' is a control character.

    c is considered a control character if
    it is outside of the extended ASCII set or
    has a code below 32 with some exclusions.
    An ASCII compatible character set is assumed.
    """
def is_control_char(c: Any) -> object {
    charcode = 0;
    try {
        charcode = ord(c);
    } except TypeError {
        charcode = c;
    }
    excludes = ("\t", "\r", "\n");
    if (charcode in [ord(char) for char in excludes]) {
        return False;
    }
    return ((charcode < 32) or (charcode > 255));
}