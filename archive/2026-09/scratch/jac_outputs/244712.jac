"""Convert string from 'string with whitespaces' to 'string_with_whitespaces'."""
def underscored(string: str) -> str {
    assert isinstance(string, str);
    return string.replace(' ', '_');
}