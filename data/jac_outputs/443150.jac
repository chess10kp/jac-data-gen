"""Clean a string. Trims whitespace."""
def clean_string(string: str) -> str {
    assert isinstance(string, str);
    clean_str = string.strip();
    clean_str = clean_str.replace("  ", " ");
    assert isinstance(clean_str, str);
    return clean_str;
}