"""Check if the given bytes string is utf-8 decodable."""
def is_utf8(bs: Any) -> object {
    try {
        bs.decode('utf-8');
        return True;
    } except UnicodeDecodeError {
        return False;
    }
}