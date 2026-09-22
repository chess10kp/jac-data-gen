"""Change least significant bit of a byte"""
def add_bit_least_significant(pixel_part: Any, bit: Any) -> object {
    pixel_part_binary = bin(pixel_part);
    last_bit = int(pixel_part_binary[-1]);
    calculated_last_bit = last_bit & bit;
    return int((pixel_part_binary[:-1] + str(calculated_last_bit)), 2);
}