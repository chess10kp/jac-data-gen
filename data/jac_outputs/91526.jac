"""Caps the string at 75 characters. If longer than 75 it's capped at max_length-3
    and '...' is appended
    """
def _to_short_string(text: str, max_length: int = 75) -> str {
    if len(text) < max_length {
        return text;
    }
    return text[0:72] + "...";
}