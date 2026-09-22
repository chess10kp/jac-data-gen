"""Adds escape characters for a string."""
def clean(s: str) -> str {
    s = s.replace('{', '\\{');
    s = s.replace('}', '\\}');
    s = s.replace('_', '\\_');
    s = s.replace('%', '\\%');
    return s;
}