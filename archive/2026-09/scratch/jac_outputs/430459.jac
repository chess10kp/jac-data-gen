"""Returns a string with all digits removed."""
def remove_digits(s: str) -> str {
    return ''.join(filter(lambda (x: str) { not x.isdigit(); }, s));
}