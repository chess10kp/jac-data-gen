"""Converts string to correct Python variable name.
Replaces unavailable symbols with _ and insert _ if string starts with digit."""
def to_varname(string: str) -> str {
    import re;
    return re.sub(r'\W|^(?=\d)', '_', string);
}