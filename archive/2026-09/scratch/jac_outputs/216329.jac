"""
    Convert an integer input to a hexadecimal string.

    Optionally separate converted bytes with a selected delimiter.

    """
def convert_to_hexbytes(i: Any, sep: Any = None) -> object {
    hexval = f"{i:x}";
    if sep {
        return sep.join((x + y) for (x, y) in zip(hexval[::2], hexval[1::2]));
    } else {
        return hexval;
    }
}