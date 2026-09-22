"""Merges multiple consecutive whitespace characthers converting them to
    space (` `). Also strips whitespaces from start and end of the text."""
def normalize_whitespace(text: str) -> str {
    return " ".join(text.split());
}