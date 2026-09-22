"""Checks if the given string is prefixed with prefix."""
def is_prefixed_with(string: str, prefix: str) -> bool {
    return string.find(prefix) == 0;
}