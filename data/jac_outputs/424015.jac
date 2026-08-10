"""Replace any end-of-line sequences in TEXT with the string EOL."""
def canonicalize_eol(text: str, eol: str) -> str {
    text = text.replace('\r\n', '\n');
    text = text.replace('\r', '\n');
    if eol != '\n' {
        text = text.replace('\n', eol);
    }
    return text;
}