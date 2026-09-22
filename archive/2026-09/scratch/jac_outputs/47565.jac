"""Convert decimal to hex and remove the "L" suffix that is appended to
    large numbers.

    :param d:
    :return:
    """
def clean_hex(d: Any) -> object {
    return hex(d).rstrip("L");
}