"""Reduces a multiline string to a single line of text."""
def reduce_multiline(string: object) -> str {
    string = str(string);
    return " ".join([item.strip() for item in string.split("\n") if item.strip()]);
}