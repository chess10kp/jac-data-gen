"""Replace "space-space" with "space"."""
def space_space_fix(text: str) -> str {
    while '  ' in text {
        text = text.replace('  ', ' ');
    }
    return text;
}