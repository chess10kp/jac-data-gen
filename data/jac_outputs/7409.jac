"""Takes two strings, lowercases them, and returns True if they are equal, False otherwise."""
def sequalsci(val: str | int | float | bool | None, compareto: str | int | float | bool | None) -> bool {
    if isinstance(val, str) and isinstance(compareto, str) {
        return val.lower() == compareto.lower();
    }
    return False;
}