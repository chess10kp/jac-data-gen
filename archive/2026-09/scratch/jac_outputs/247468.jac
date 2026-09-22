"""Return whether the text looks like it has ANSI color codes."""
def looks_like_ansi_color(text: str) -> bool {
    return '\x1b[' in text;
}