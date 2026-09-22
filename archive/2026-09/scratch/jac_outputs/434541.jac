"""Replace double quotes in text."""
def _applescriptify(text: str) -> str {
    return text.replace('"', '" + quote + "');
}