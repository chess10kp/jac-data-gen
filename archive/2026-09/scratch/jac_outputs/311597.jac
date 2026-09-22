"""Encode a string assuming UTF-8 encoding."""
def encode(val: str | bytes | list[str | bytes] | tuple[str | bytes, ...]) -> bytes | list[bytes] {
    if isinstance(val, (list, tuple)) {
        return [encode(v) for v in val] as list[bytes];
    } elif isinstance(val, str) {
        return val.encode('utf-8');
    } else {
        return val;
    }
}