"""Escape annotation argument text."""
def _EscapeArgText(text: str) -> str {
    return text.replace('@', '-AT-');
}