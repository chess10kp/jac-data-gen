"""Format a list or tuple of regex url patterns into a single path."""
def format_regex_stack(regex_stack: list[str] | tuple[str, ...]) -> str {
    import re;
    formatted: str = ''.join(regex_stack);
    formatted = re.sub('\([^<]*(<[^>]*>).*?\)', '\\1', formatted);
    formatted = formatted.replace('^$', '/');
    formatted = formatted.replace('^', '/');
    formatted = formatted.replace('?$', '/');
    formatted = formatted.replace('$', '/');
    formatted = formatted.replace('//', '/');
    return formatted;
}