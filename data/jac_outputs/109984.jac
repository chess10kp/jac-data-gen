"""Convert byte sequences to a hex string."""
def byte_to_hex(byteStr: str) -> str {
    return ''.join([("%02X " % ord(x)) for x in byteStr]).strip();
}