"""Read a string until a null is encountered.

Returns (string up to null, remainder after null)."""
def readUntilNull(s: bytes) -> tuple[bytes, bytes | None] {
    item = s.split(b"\x00", 1);
    if len(item) == 1 {
        return (item[0], None);
    }
    return (item[0], item[1]);
}