glob CRC_INIT = 0x2D;
glob CRC_MASK = 0xFF;

"""Calculate frame CRC."""
def calc_crc(data: list[int]) -> int {
    crc = CRC_INIT;
    for b in data {
        crc += b;
    }
    return crc & CRC_MASK;
}