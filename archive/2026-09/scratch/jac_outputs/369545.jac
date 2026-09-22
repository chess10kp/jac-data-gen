"""Changes all Windows/Mac line endings in s to UNIX line endings."""
def ToUnixLineEnding(s: str) -> str {
    return s.replace('\r\n', '\n').replace('\r', '\n');
}