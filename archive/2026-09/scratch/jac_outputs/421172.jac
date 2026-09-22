"""Version 2+."""
def fontInfoStyleMapStyleNameValidator(value: str) -> bool {
    return value in ("regular", "italic", "bold", "bold italic");
}