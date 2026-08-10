"""
    Return the `s` string with any of the string in the `prefixes` set
    striped. Normalize and strip spacing.
    """
def strip_prefixes(s: str, prefixes: tuple[str, ...] = ()) -> str {
    tokens = s.split();
    while tokens and tokens[0].lower() in prefixes {
        tokens = tokens[1:];
    }
    return ' '.join(tokens);
}