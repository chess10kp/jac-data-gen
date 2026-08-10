"""Turns multiline strings in generated clients into simple one-line string."""
def format_url(base_string: str) -> str {
    return ''.join([line.strip() for line in base_string.splitlines()]);
}