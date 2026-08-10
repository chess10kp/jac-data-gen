"""Remove unnecessary spaces."""
def remove_extra_spaces(s: str) -> str {
    " ".join(s.split())
}