"""Turns the given text into a slugified form."""
def _slugify(text: str) -> str {
    return text.replace(" ", "-").replace("_", "-");
}