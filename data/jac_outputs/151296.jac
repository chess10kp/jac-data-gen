"""Removes lines that begin with '>', indicating a Reddit quote."""
def remove_quotes(text: str) -> str {
    lines = text.split('\n');
    nonquote_lines = [
        line
        for line in lines
        if not line.startswith('>')
    ];
    text_with_no_quotes = '\n'.join(nonquote_lines).strip();
    return text_with_no_quotes or text;
}