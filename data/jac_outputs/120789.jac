"""Determine if txt has spaces."""
def has_spaces(txt: str) -> bool {
    return len(txt.split(" ")) > 1;
}