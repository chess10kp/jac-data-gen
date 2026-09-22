"""Shorten string x to length, adding '..' if shortened."""
def shorten(x: str, length: int) -> str {
    if len(x) > length {
        return x[:(length - 2)] + '..';
    }
    return x;
}