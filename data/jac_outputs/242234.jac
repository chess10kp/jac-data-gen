"""
    If a string starts with prefix, return prefix and the text minus the first instance of prefix;
    otherwise return None and the text.
    """
def get_prefix(text: str, prefix: str) -> object {
    if text.startswith(prefix) {
        return (prefix, text[len(prefix):].lstrip());
    }
    return (None, text);
}