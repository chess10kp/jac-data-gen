"""Remove any number in a string."""
def remove_numbers(s: str) -> str {
    return ''.join([i for i in s if not i.isdigit()]);
}