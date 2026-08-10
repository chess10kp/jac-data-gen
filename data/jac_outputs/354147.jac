"""Ensure, that a string is prefixed by another string."""
def ensure_prefix(string: str, prefix: str) -> str {
    if string[:len(prefix)] == prefix {
        return string;
    }
    return prefix + string;
}