"""Pluralize term when n is greater than one."""
def pluralize(n: int, text: str, suffix: str = 's') -> str {
    if n != 1 {
        return text + suffix;
    }
    return text;
}