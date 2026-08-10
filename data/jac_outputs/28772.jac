"""Return verbatim a given string if it is not empty or None otherwise."""
def normalize_empty_to_none(text: str) -> str | None {
    text if text != "" else None
}