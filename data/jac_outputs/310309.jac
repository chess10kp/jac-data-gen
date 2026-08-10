"""Normalise the whitespace in the string."""
def normalise_whitespace(text: str) -> str {
    return " ".join(text.strip().split());
}