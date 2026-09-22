"""
    Read a key and value from a line.
    Only splits on first instance of separator.
    """
def read_key_value(line: str, separator: str = '=') -> tuple[str, str] {
    (key, value) = line.split(separator, 1);
    return (key.strip(), value.strip());
}