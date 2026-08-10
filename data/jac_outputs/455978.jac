"""
Test whether a string can be converted to float.
"""
def is_number(s: str) -> bool {
    try {
        float(s);
        return True;
    } except ValueError {
        return False;
    }
}