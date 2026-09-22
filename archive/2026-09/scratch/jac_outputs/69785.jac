"""Strips string to left of and including specified characters."""
def r_split(_: str, text: str, char: str) -> str {
    return text.split(char)[-1];
}