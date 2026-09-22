"""Formats markup text into italics."""
def italicize(text: str | int | float | bool) -> str {
    return "*" + str(text) + "*";
}