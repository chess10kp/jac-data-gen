"""Ellipsize the string if len >= max_size, otherwise return the original."""
def ellipsize(msg: str, max_size: int = 80) -> str {
    if len(msg) >= max_size {
        return ("%s (...)" % msg[0:(max_size - 6)]);
    }
    return msg;
}