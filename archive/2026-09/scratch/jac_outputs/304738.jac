glob HEX_RADIX = 16;

"""
    For a given number of subgraphs, return a common prefix that yields around
    16 subgraphs.

    >>> [common_prefix(n) for n in (0, 1, 31, 32, 33, 512+15, 512+16, 512+17)]
    ['', '', '', '', '1', 'f', '01', '11']
    """
def common_prefix(n: int) -> str {
    hex_digits = "0123456789abcdef";
    return hex_digits[n % HEX_RADIX] + common_prefix(n // HEX_RADIX) if n > 2 * HEX_RADIX else "";
}