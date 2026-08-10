"""bytes/str/int/float type to bytes."""
def b(s: bytes | str | int | float, encoding: str = "utf-8") -> bytes {
    if isinstance(s, bytes) {
        return s;
    } elif isinstance(s, (str, int, float)) {
        return str(s).encode(encoding);
    } else {
        raise TypeError(`type(s));
    }
}