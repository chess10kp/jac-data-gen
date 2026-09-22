"""Return text with trailing spaces."""
def get_formatted_string(text: str, width: int, formatted: bool = True) -> str {
    return (" " + text + " " + (" " * (width - len(text)))) if formatted else text;
}