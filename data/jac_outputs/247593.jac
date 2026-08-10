"""Force string to ascii."""
def to_ascii(s: bytes) -> str {
    s = s.split(b'\x00', 1)[0];
    return s.decode('ascii', 'ignore').lower();
}