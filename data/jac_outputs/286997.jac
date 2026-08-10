"""Convert a null-terminated C-string bytes to a Python string."""
def cstr2str(cs: bytes, encoding: str = 'utf8') -> str {
    return cs.split(b'\x00', 1)[0].decode(encoding);
}