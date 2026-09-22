"""Return a copy of string that has all non-allowed characters replaced by a new character (default: underscore)."""
def clean_str(
    str_: str,
    illegal_chars: tuple[str, ...] = (' ', '\t', ',', ';', '|'),
    replacement_char: str = '_'
) -> str {
    new_string = str(str_);
    for illegal_char in illegal_chars {
        new_string = new_string.replace(illegal_char, replacement_char);
    }
    return new_string;
}