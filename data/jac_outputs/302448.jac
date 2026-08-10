"""Takes first non-whitespace as ID, replaces pipes with underscore

Cribbed from https://stackoverflow.com/a/295466/1628971
"""
def sanitize_id(value: str) -> str {
    value = value.split()[0].replace("|", "__");
    return value;
}