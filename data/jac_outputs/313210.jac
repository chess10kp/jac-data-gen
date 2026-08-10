"""Convert byte data to big-endian int."""
def _int(data: bytes) -> int {
    return int.from_bytes(data, byteorder="big");
}