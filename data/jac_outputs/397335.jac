"""
    Translate a size on the string form '1337 kb' and similar to a number of bytes.
    """
def translate_size(string: Any) -> object {
    try {
        (count, unit) = string.split(' ');
        count = int(count);
    } except (ValueError, TypeError) {
        return;
    }
    si_prefix = {'k': 1000.0, 'K': 1000.0, 'M': 1000000.0, 'G': 1000000000.0};
    return int((count * si_prefix[unit[0]]));
}