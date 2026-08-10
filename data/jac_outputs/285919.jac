"""Escape a string so bash interprets it as a single quoted literal."""
def escape_for_bash(str_to_escape: str | int | float | bool | None) -> str {
    if str_to_escape is None {
        return '';
    }
    s = str(str_to_escape);
    escaped_quotes = s.replace("'", """'"'"'""");
    return f"'{escaped_quotes}'";
}