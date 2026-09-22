"""Return [string] with UNIX-style line endings"""
def with_unix_endl(string: str) -> str {
    return string.replace("\r\n", "\n").replace("\r", "");
}