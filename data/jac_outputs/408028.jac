"""Inserts a space to text if it is not empty and returns it."""
def _Append(text: str) -> str {
    if not text {
        return '';
    }
    if text[-1].isspace() {
        return text;
    }
    return ' ' + text;
}