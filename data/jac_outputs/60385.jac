"""
    Read the bytes of the steg_bytes from the offset until the ending byte sequence is found.
    Return the bytes read and the offset of the ending byte sequence.
    """
def read_until(steg_bytes: bytes, offset: int, ending: str) -> tuple[bytes, int] | None {
    bytes_read = b'';
    while offset < len(steg_bytes) {
        if steg_bytes[offset:(offset + len(ending))] == ending.encode() {
            return (bytes_read, offset);
        }
        bytes_read += steg_bytes[offset:(offset + 1)];
        offset += 1;
    }
}