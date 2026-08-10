"""Check whether a value is a standard floating-point literal."""
def istradiationalfloat(value: str | int | float) -> bool {
    try {
        float(value);
        return True;
    } except ValueError {
        return False;
    }
}