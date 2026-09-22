"""Return line ending."""
def get_line_ending(line: str) -> str {
    non_whitespace_index = len(line.rstrip()) - len(line);
    if not non_whitespace_index {
        return '';
    }
    return line[non_whitespace_index:];
}