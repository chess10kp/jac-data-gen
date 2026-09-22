"""set a bit in a bitstring, 0 = MSB."""
def set_bitstring_bit(bitstring: bytes, bitnum: int, valuetoset: bool) -> bytes {
    bytepos = bitnum >> 3;
    bitpos = 7 - bitnum % 8;
    bytevalue = bitstring[bytepos];
    mask = 1 << bitpos;
    if valuetoset {
        if bytevalue & mask {
            return bitstring;
        }
        return (
            bitstring[:bytepos]
            + (bytevalue + mask).to_bytes(1, byteorder='big')
            + bitstring[bytepos + 1:]
        );
    }
    if bytevalue & mask {
        return (
            bitstring[:bytepos]
            + (bytevalue - mask).to_bytes(1, byteorder='big')
            + bitstring[bytepos + 1:]
        );
    }
    return bitstring;
}