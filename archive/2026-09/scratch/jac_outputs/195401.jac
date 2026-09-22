"""Runs basic whitespace cleaning and splitting on a piece of text."""
def whitespace_tokenize(text: str) -> list[str] {
    text = text.strip();
    if not text {
        return [];
    }
    return text.split();
}