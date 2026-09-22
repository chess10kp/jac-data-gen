"""Remove newline characters from text."""
def transformation_remove_nl(text: str, *args: str) -> str {
    _ = args;
    return text.replace('\r\n', '').replace('\n', '');
}