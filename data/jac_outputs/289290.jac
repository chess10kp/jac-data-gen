"""
    Calculate the maximum length needed to stock a base64 encoded stream of
    bytes.
    @param byte_length: Length of byte stream.
    @return: The length needed in byte.
    """
def Base64Length(byte_length: Any) -> object {
    return ((((byte_length + 3) - (byte_length % 3)) / 3) * 4);
}