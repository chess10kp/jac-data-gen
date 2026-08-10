"""
    convert byte to GB
    :param byte_number: byte number
    :return: GB
    """
def byte_to_gb(byte_number: Any) -> object {
    return (byte_number / (1024 ** 3));
}