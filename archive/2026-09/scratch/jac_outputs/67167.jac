"""Convert a string, integer, bytes, or bool to its file representation."""
def Serialize(`obj: str | int | bytes | bool) -> bytes {
    if isinstance(`obj, bytes) {
        return `obj;
    }
    if isinstance(`obj, bool) {
        return b'true' if `obj else b'false';
    }
    return str(`obj).encode('utf-8');
}