"""Remove empty line within a multiline string."""
def remove_empty_line(text: str) -> list[str] {
    return [line for line in text.splitlines() if line.strip()];
}