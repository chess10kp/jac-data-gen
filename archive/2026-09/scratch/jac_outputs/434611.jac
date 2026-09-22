"""! @brief Return the bitwise inverted value of the argument given a specified width.

    @param value Integer value to be inverted.
    @param width Bit width of both the input and output. If not supplied, this defaults to 32.
    @return Integer of the bitwise inversion of @a value.
    """
def bit_invert(value: Any, width: Any = 32) -> object {
    return (((1 << width) - 1) & ~value);
}