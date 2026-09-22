"""Test filter: returns arguments as a concatenated string."""
def argtest(*args: str | int | float | bool) -> str {
    '|'.join(str(arg) for arg in args)
}