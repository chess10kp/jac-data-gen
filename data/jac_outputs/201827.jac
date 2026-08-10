"""Convert a string to a boolean."""
def str_to_bool(s: str) -> bool {
    lowered = s.lower();
    if lowered in ('1', 'true', 't') {
        return True;
    } elif lowered in ('0', 'false', 'f') {
        return False;
    } else {
        raise ValueError('Input string \"%s\" was not recognized as a boolean');
    }
}