"""Parses an unsigned integer from data that is `bitlen` bits long."""
def parse_unsigned_int(data: bytes, bitlen: int) -> int {
    val = '0b' + ''.join([f'{b:08b}' for b in data]);
    return int(val[0:(2 + bitlen)], 2);
}