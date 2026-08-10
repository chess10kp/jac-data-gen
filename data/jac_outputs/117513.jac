"""Wrap text into an HTML `h` tag."""
def h(level: int, text: str) -> str {
    return f"<h{str(level)}>{text}</h{level}>";
}