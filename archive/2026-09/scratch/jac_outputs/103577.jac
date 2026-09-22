"""Check whether a value can be converted to an integer."""
def rep_int(value: str | int | float | bool) -> bool {
    try {
        int(value);
        return True;
    } except ValueError {
        return False;
    }
}