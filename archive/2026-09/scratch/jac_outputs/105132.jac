"""Convert a string to lowercase with capitalized initials."""
def capitalize_text(text: str) -> str {
    return ' '.join([w.capitalize() for w in text.lower().split(' ')]);
}