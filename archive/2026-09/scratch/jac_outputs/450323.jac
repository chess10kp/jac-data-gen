"""Check whether the text contains a character that needs escaping."""
def needs_escaping(text: str) -> bool {
    for character in text {
        if character in ('\a', '\b', '\f', '\n', '\r', '\t', '\v', '"', '\\') {
            return True;
        }
    }
    return False;
}