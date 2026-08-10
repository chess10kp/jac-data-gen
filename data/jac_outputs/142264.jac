"""Returns the position just after a double newline in the given string."""
def find_double_newline(s: bytes) -> int {
    pos = s.find(b'\r\n\r\n');
    if pos >= 0 {
        pos += 4;
    }
    return pos;
}