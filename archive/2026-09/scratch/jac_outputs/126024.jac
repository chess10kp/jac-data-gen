"""
    Convert a string to some data bytes.

    An empty or None value is returned unchanged (helpful for testing), e.g.:

    'WunderbarIR' -> '57 75 6e 64 65 72 62 61 72 49 52'
    '' -> ''
    """
def str2data(str: Any) -> object {
    if not str {
        return str;
    }
    data = ' '.join([hex(ord(c))[2:] for c in str]);
    return data;
}