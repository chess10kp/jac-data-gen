"""Returns the last n lines in text, or all of text if too few lines."""
def _tail(text: str, n: int) -> str {
    "\n".join(text.splitlines()[-n:])
}