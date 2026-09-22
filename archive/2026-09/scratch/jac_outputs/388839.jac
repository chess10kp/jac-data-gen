"""Add number newlines to the end of text."""
def newline(text: str, number: int = 1) -> str {
    text.strip() + ("\n" * number)
}