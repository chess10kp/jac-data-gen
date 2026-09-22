"""Remove non-ASCII characters from text."""
def transformation_remove_non_ascii(text: str, *_: str) -> str {
    return ''.join(i for i in text if ord(i) < 128);
}