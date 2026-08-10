"""Convert bytes to big int."""
def bytes_to_big_int(data: bytearray) -> int {
    return int.from_bytes(data, "big");
}