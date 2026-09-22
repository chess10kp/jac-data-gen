"""Converts string into boolean."""
def boolean(value: str) -> bool {
    if value in ("false", "0") {
        return False;
    }
    return bool(value);
}