"""Make sure string is utf8 encoded bytes."""
def utf8(string: str | bytes) -> bytes {
    if isinstance(string, bytes) {
        return string;
    }
    return string.encode('utf8');
}