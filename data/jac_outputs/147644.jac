glob MASK_BYTE = 255;

"""Extract bit field value from a byte using [index, bits] schema."""
def byte_bit_value(byte: int, schema: list[int]) -> int {
    (index, bits) = schema;
    if index < 0 or index > 7 {
        raise ValueError("Schema index must be 0 thru 7");
    }
    if bits < 1 or bits > 8 {
        raise ValueError("Schema bits must be 1 thru 8");
    }
    if len(bin(byte)[2:]) > 8 {
        raise ValueError("Number too big. Not a byte value.");
    }
    if index == 0 and bits == 8 {
        return byte;
    }
    shift = 8 - (index + bits);
    mask = MASK_BYTE >> (shift + index);
    return (byte >> shift) & mask;
}