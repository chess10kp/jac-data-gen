"""
    Reverse a hex string, bf99 -> 99bf
    """
def hex_reverse(integer: Any, size: Any) -> object {
    string = '{0:0{1}x}'.format(integer, size);
    return ''.join([string[(i - 2):i] for i in range(len(string), 0, -2)]);
}