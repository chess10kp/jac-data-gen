"""Anchor a regex pattern to the start and end of the input string."""
def cap_match_string(`match: str) -> str {
    return '^' + `match + '$';
}