glob BYTE_MASK = 0xFF;

"""Calculates the checksum, given a message without the STX and ETX.
Returns a list with the ordered checksum bytes"""
def checksum(data: bytes | list[int]) -> bytearray {
    calc_sum = 0;
    for i in data {
        calc_sum += i;
    }
    low_sum = (calc_sum >> 8) & BYTE_MASK;
    high_sum = calc_sum & BYTE_MASK;
    return bytearray([high_sum, low_sum]);
}