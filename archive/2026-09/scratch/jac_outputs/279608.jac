""" Utility method to convert a file size in bytes to a human-readable format

    Args:
        num    (int): Number of bytes
        suffix (str): Suffix for 'bytes'

    Returns:
        str: The formatted file size as a string, eg. ``1.21 GB``
    """
def sizeof(num: int | float, suffix: str = 'B') -> str {
    for unit in ['', 'K', 'M', 'G', 'T', 'P', 'E', 'Z'] {
        if abs(num) < 1024.0 {
            return "%3.1f %s%s" % (num, unit, suffix);
        }
        num /= 1024.0;
    }
    return "%.1f %s%s" % (num, 'Y', suffix);
}