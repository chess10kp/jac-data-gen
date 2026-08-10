"""Strip string."""
def strip_str(string: str) -> str {
    return string.strip('"').strip("'").strip();
}