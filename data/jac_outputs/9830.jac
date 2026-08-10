"""Truncates text and adds ellipses at the end. Does not truncate words in the middle."""
def ellipsis_after(text: str, length: int) -> str {
    if not text or len(text) <= length {
        return text;
    }
    return text[:length].rsplit(' ', 1)[0] + "\u2026";
}