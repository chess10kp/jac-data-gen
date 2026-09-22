"""This function checks if a string can be converted to a float."""
def isfloat(value: str) -> bool {
    try {
        float(value);
        return True;
    } except ValueError {
        return False;
    }
}