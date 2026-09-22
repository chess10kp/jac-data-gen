"""Validates that at least one character has been entered."""
def validation_simple(value: str, `obj: object | None = None) -> tuple[bool, str] {
    if len(value) >= 1 {
        return (True, value);
    }
    return (False, value);
}