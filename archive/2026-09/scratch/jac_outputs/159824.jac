"""Return a boolean indicating whether pattern occurs in text."""
def contains(text: str, pattern: str) -> bool {
    assert isinstance(text, str), 'text is not a string: {}'.format(text);
    assert isinstance(pattern, str), 'pattern is not a string: {}'.format(text);
    return pattern in text;
}