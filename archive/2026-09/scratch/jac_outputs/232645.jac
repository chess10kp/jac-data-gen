"""
    Convert a byte string to a unicode string
    :param b: byte string
    :return: unicode string
    """
def as_unicode(b: Any) -> object {
    try {
        b = b.decode();
    } except (AttributeError, UnicodeDecodeError) {
        ;
    }
    return b;
}