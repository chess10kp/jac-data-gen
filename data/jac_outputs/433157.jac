"""Removes a prefix substring from a given string."""
def remove_prefix(string: str, prefix: str) -> str {
    return string[len(prefix):];
}