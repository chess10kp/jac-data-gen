"""Elide text so it uses a maximum of length chars."""
def elide(text: str, length: int) -> str {
    if length < 1 {
        raise ValueError("length must be >= 1!");
    }
    if len(text) <= length {
        return text;
    }
    return text[:(length - 1)] + '\u2026';
}