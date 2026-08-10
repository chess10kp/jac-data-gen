"""Create a DMAP tag with uint16 data."""
def uint16_tag(name: str, value: int) -> bytes {
    return name.encode('utf-8') + b'\x00\x00\x00\x02' + value.to_bytes(2, byteorder='big');
}