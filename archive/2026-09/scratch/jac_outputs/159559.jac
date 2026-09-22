"""Filter out the digits in the string."""
def only_digit(s: str) -> str {
    ''.join([c for c in s if c.isdigit()])
}