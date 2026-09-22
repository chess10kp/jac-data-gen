glob BYTE_MASK = 255;

"""Make int` "degree polynomial" in which each bit represents a degree who's coefficient is 1"""
def make_poly(bit_length: int, msb: bool = False) -> int {
    num_bytes = int(bit_length / 8);
    if msb {
        return 1 << ((8 * num_bytes) - 1);
    }
    result = 0;
    for x in range(num_bytes) {
        result += BYTE_MASK << (x * 8);
    }
    return result;
}