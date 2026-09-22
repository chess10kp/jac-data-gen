"""Converts named character references in the given string to the corresponding
    Unicode characters. I didn't notice any numeric character references in this
    dataset.
    """
def recover_escape(text: str) -> str {
    return text.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">");
}