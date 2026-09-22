"""Returns the hexadecimal representation of ``s``"""
def encode_str(s: str) -> str {
    ''.join("%02x" % ord(n) for n in s)
}