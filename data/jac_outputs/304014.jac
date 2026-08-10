"""Returns the string s, with reverse-video removed."""
def stripReverse(s: str) -> str {
    return s.replace('\x16', '');
}