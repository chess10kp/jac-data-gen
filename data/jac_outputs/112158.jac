"""
    Convert binary string into hex string
    :param binary_string: binary string
    :param min_width: width of hex string
    :return:
    """
def bin_to_hex(binary_string: Any, min_width: Any = 0) -> object {
    return '{0:0{width}x}'.format(int(binary_string, 2), width=min_width);
}