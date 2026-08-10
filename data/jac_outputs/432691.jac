"""Return True if 's' can be converted in a float."""
def IsNumber(s: str) -> bool {
    try {
        v = float(s);
        return True;
    } except ValueError {
        return False;
    }
}