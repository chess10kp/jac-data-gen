"""Checks if a string can be converted to int."""
def str_is_int(s: str) -> bool {
    if not isinstance(s, str) {
        raise TypeError('str_is_int function only accepts strings.');
    }
    try {
        int(s);
        return True;
    } except ValueError as e {
        if 'invalid literal' in str(e) {
            return False;
        }
        raise e;
    }
}