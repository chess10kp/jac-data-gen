"""
    Many of the rogue variables are returned as UTF8 formatted
    int arrays. This function changes them from UTF8 to a
    string
    """
def utf8_to_str(d: list[bytes]) -> str {
    return ''.join([str(s, encoding='UTF-8') for s in d]);
}