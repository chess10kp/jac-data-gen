"""Removes a prefix from the string, if it exists."""
def remove_prefix(string: str, prefix: str) -> str {
    if string.startswith(prefix) {
        return string[len(prefix):];
    } else {
        return string[:];
    }
}