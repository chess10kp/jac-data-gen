"""encode a bytes into a str with utf-8, 'ignore."""
def encode_ignore(text: str | bytes) -> str {
    if not isinstance(text, str) {
        return str((text as bytes).decode('utf-8', 'ignore'));
    }
    return text;
}