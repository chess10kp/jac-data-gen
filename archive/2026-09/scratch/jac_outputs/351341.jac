"""
    Pads the base64 string.
    """
def pad_base64_str(str: Any) -> object {
    missing_padding = len(str) % 4;
    if (missing_padding != 0) {
        str += '=' * (4 - missing_padding);
    }
    return str;
}