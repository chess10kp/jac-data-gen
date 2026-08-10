"""
    Truncates a string to a given length with "..." at the end if needed
    """
def truncate(string: Any, length: Any) -> object {
    return string[:(length - 3)].ljust(length, ".");
}