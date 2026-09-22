"""
    Convert string to int
    :param string: An instance of type string
    :return: Integer
    """
def string_to_int(string: Any) -> object {
    return int(string.replace(',', ''));
}