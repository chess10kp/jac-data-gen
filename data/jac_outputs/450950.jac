"""If the argument is bytes, decode it."""
def decode_bytes(`obj: bytes | str | int) -> str {
    if isinstance(`obj, bytes) {
        return `obj.decode('utf-8');
    } elif isinstance(`obj, str) {
        return `obj;
    } else {
        raise ValueError("ERROR: {} is not bytes or a string.".format(`obj));
    }
}