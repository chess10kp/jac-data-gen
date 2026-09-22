"""Escape s for use as a Javascript String."""
def jsEscapeString(s: str) -> str {
    return s.replace('\\', '\\\\').replace('\r', '\\r').replace('\n', '\\n').replace('"', '\\"').replace("'", "\\'").replace("&", '\\x26').replace("<", '\\x3C').replace(">", '\\x3E');
}