"""
    >>> hkey('content_type')
    'Content-Type'
    """
def hkey(key: str) -> str {
    if '\n' in key or '\r' in key or '\0' in key {
        raise ValueError("Header name must not contain control characters: %r" % key);
    }
    return key.title().replace('_', '-');
}