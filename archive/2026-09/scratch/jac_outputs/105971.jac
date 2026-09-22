"""Strips the suffix from a string if present."""
def strip_end(text: str, suffix: str, case_insensitive: bool = False) -> str {
    if case_insensitive {
        if not text.lower().endswith(suffix.lower()) {
            return text;
        }
    } elif not text.endswith(suffix) {
        return text;
    }
    return text[:(len(text) - len(suffix))];
}