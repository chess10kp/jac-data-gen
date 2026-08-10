"""Truncates a string for a given length."""
def cut_string(s: str, length: int = 100) -> str {
    if 0 <= length < len(s) {
        return f"{s[:length]}...";
    }
    return s;
}