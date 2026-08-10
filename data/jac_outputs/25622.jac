"""Replace specific unicode characters with ASCII ones."""
def format_string(string: str) -> str {
    string.replace("\u2013", "-").replace("\u00a0", " ").replace("\u2018", "'").replace("\u2019", "'").replace("\u201c", '"').replace("\u201d", '"').replace("\u00ed", 'i');
    return string;
}