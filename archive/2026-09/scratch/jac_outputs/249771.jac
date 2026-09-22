import from binascii { b2a_base64 }

"""
    >>> base64encode('hello')
    'aGVsbG8='
    """
def base64encode(string: str, layer: int = 1) -> str {
    if layer > 0 {
        return base64encode(
            b2a_base64(string.encode('UTF-8')).decode().replace("\n", ""),
            layer - 1
        );
    }
    return string;
}