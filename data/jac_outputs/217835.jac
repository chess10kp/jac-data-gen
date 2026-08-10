"""Return string with quotes changed to preferred_quote if possible."""
def unify_quotes(token_string: str, preferred_quote: str) -> str | None {
    bad_quote = {'"': "'", "'": '"'}[preferred_quote];
    allowed_starts = {
        '': bad_quote,
        'f': 'f' + bad_quote,
        'r': 'r' + bad_quote,
        '': '' + bad_quote,
        'b': 'b' + bad_quote
    };
    if not any(token_string.startswith(start) for start in allowed_starts.values()) {
        return token_string;
    }
    if token_string.count(bad_quote) != 2 {
        return token_string;
    }
    if preferred_quote in token_string {
        return token_string;
    }
    assert token_string.endswith(bad_quote);
    assert len(token_string) >= 2;
    for (prefix, start) in allowed_starts.items() {
        if token_string.startswith(start) {
            chars_to_strip_from_front = len(start);
            return '{prefix}{preferred_quote}{token}{preferred_quote}'.format(
                prefix=prefix,
                preferred_quote=preferred_quote,
                token=token_string[chars_to_strip_from_front:-1]
            );
        }
    }
}