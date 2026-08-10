"""Returns the minimum number of bits needed to fit given positive
    integer.

    """
def integer_as_number_of_bits(size: Any) -> object {
    if (size == 0) {
        return 0;
    } else {
        return size.bit_length();
    }
}