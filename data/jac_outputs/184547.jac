"""Remove characters that may be changed when reformatting the text with black."""
def black_invariant(text: str, chars: list[str] | None = None) -> str {
    if chars is None {
        chars = [' ', '\t', '\n', ',', "'", '"', '(', ')', '\\'];
    }
    for char in chars {
        text = text.replace(char, '');
    }
    return text;
}