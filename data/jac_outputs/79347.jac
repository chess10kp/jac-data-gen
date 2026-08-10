"""Take an integer as input and return the bits written version."""
def int_to_bits(i: int) -> object {
    return "{:0{}b}".format(i, i.bit_length());
}