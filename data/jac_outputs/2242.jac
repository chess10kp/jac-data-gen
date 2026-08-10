"""Return a byte string, encoding text inputs with the given encoding."""
def to_bytes(`obj: str | bytes, encoding: str = 'utf-8', errors: str = 'strict') -> bytes {
    if isinstance(`obj, bytes) {
        return `obj;
    }
    return bytes(`obj, encoding=encoding, errors=errors);
}