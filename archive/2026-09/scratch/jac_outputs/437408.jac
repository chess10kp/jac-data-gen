"""
    Simple callable method to remove additional newline characters at the end
    of a given string.
    """
def chomp(string: str) -> str {
    if string.endswith("\r\n") {
        return string[:-2];
    }
    if string.endswith("\n") {
        return string[:-1];
    }
    return string;
}