""" Convert the hex representation of the number to a correctly ordered
    string.

    Parameters
    ----------
    val: int
        The integer representing the string. This is in reverse order.
        Ie. XXYYZZ -> chr(ZZ)chr(YY)chr(XX)

    Returns
    -------
    str
        The actual string.
    """
def hex_to_chars(num: Any) -> object {
    return (
        chr((num & 255)) + chr(((num & 65280) >> 8)) + chr(((num & 16711680) >> 16))
    );
}