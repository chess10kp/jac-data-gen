"""Convert bytes to str."""
def bytes_to_str(s: bytes | str) -> str {
    if isinstance(s, bytes) {
        return s.decode(errors='replace');
    }
    return s;
}