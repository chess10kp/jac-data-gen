"""
    Return a text formatted for use in a Debian control file with proper
    continuation for multilines.
    """
def as_formatted_lines(lines: list[str]) -> str {
    if not lines {
        return '';
    }
    formatted = [];
    for line in lines {
        stripped = line.strip();
        if stripped {
            formatted.append(' ' + line);
        } else {
            formatted.append(' .');
        }
    }
    return '\n'.join(formatted).strip();
}