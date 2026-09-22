""" Make a canonical text version of a code - a 5 digit, 0-padded string
    """
def sanitize_code(code: Any) -> object {
    try {
        code = "%05i" % code;
    } except TypeError {
        code = str(code);
    }
    return code;
}