"""
    Convert string to integer without raising exceptions
    :param s: integer string
    :param base: numbering base
    :return: integer value or None on failure
    """
def int_of_string_opt(s: str, base: int = 10) -> int | None {
    try {
        return int(s, base);
    } except Exception {
        return None;
    }
}