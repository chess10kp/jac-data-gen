"""Returns a copy of the string from which the multi-character prefix has been stripped."""
def strip_prefix(string: str, prefix: str) -> str {
    if string.startswith(prefix) {
        return string[len(prefix):];
    }
    return string;
}