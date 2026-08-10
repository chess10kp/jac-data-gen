"""
Ensure that whatever type of string is incoming, it is returned as an
actual string, versus 'bytes' which Python 3 likes to use.
"""
def as_string(string: str | bytes) -> str {
    if isinstance(string, bytes) {
        return string.decode('utf-8', 'ignore');
    }
    return string;
}