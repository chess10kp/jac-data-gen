"""Checks if string contains only ascii chars."""
def is_ascii(str_data: str) -> bool {
    try {
        str_data.encode('ascii');
    } except (UnicodeEncodeError, AttributeError) {
        return False;
    }
    return True;
}