"""
    Takes a key and returns the line number in it
    :param key: The key to parse
    :return: line number
    """
def from_key_to_line_number(key: str) -> int {
    n = key.split(".", 2)[1];
    if n[-1] == "l" {
        n = n[:-1];
    }
    if not n.isdigit() {
        return -1;
    }
    line_number = int(n);
    return line_number;
}