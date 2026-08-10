"""Add trailing slash."""
def add_trailing_slash(s: str) -> str {
    if not s.endswith('/') {
        s = s + '/';
    }
    return s;
}