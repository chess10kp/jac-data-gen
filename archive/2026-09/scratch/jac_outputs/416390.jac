"""Shorten a string to a max length and end it with an ellipsis."""
def elide_text(text: str, max_length: int) -> str {
    return text if len(text) < max_length else f"{text[:max_length]}...";
}