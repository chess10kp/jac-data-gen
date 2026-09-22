"""Escape a string to allow injecting it into a json conf."""
def escaped(val: str) -> str {
    return val.replace('\\', '/').replace('"', '\"');
}