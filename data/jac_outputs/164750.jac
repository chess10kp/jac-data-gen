"""Removes all non-digits (letters, symbols, punctuation, etc.)."""
def remove_nondigits(string_arg: str) -> str {
    return ''.join([x for x in string_arg if x.isdigit() or x == '.']);
}