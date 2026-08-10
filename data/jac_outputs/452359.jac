"""strips all white-space from a string"""
def remove_whitespace(text: str | None) -> str {
    if text is None {
        return "";
    }
    return "".join(text.split());
}