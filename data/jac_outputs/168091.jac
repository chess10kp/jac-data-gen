"""Convert string into str (bytes) object."""
def ensure_str(string: str) -> str | bytes {
    if not isinstance(string, str) {
        return string.encode('utf-8');
    }
    return string;
}