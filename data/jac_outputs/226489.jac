"""Returns true if the string is convertible to float."""
def string_contains_numeric_value(s: str) -> bool {
    try {
        float(s);
        return True;
    } except ValueError {
        return False;
    }
}