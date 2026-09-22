""" Read next two bytes as a 16-bit value """
def read_16bit_size(data: bytes, little_endian: bool = True) -> int {
    if little_endian {
        return data[0] + data[1] * 256;
    }
    return data[1] + data[0] * 256;
}