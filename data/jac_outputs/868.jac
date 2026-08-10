"""convert bytestrings and numpy strings to python strings"""
def _ensure_str(s: str | bytes) -> str {
    return s.decode() if isinstance(s, bytes) else str(s);
}