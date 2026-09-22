"""Add a strikethtough effect to text."""
def strike_text(text: str) -> str {
    return ''.join([char + '\u0336' for char in text]);
}