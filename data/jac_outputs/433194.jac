"""Escape literal backslashes for use with re."""
def re_escape(string: str) -> str {
    return string.replace('\\', "\\\\");
}