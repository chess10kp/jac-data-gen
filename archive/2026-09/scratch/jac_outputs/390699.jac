""" Read a single, decimal byte from the user and return a string of its hexidecimal value. This string should use lowercase and should always be exactly two characters long. Make sure you pad the beginning with a 0 if necessary, and make sure the string does NOT start with '0x'.

    Example test case:

        255 -> "ff"

    """
def single_byte_to_hex(single_char: Any) -> object {
    hexaRep = hex(int(single_char));
    return hexaRep[2:];
}