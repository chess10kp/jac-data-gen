"""Return a value as e.g. 'FC8E', i.e. an uppercase hex string with no leading
    '0x' or trailing 'L'.
    """
def ckstr(checksum: Any) -> object {
    return hex(checksum)[2:].rstrip('L').upper();
}