"""
    Convert octal string to hexadecimal string.
    For instance: '32' -> '1a'
    """
def oct2hex(x: Any) -> object {
    return hex(int(x, 8))[2:];
}