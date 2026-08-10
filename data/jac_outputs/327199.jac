"""converts a given Text to a upper camel case text
    this is a example -> ThisIsAExample"""
def toUpperCamelCase(text: str) -> str {
    split_text = text.split();
    return ''.join(t[0:1].capitalize() + t[1:] for t in split_text);
}