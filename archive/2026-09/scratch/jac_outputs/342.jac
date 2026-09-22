""" Bytes to int """
def bytes_to_int(byte_array: bytes) -> int {
    return int.from_bytes(byte_array, byteorder='big');
}