"""Helper, checks if an assert statement ends with a message."""
def _is_line_ends_with_message(line: str) -> bool {
    line = line[::-1].replace(' ', '');
    if line[0] != "'" and line[0] != '"' {
        return False;
    }
    char = '"' if line[0] == '"' else "'";
    index_of_last_quote = line.index(char, line.index(char) + 1);
    return line[index_of_last_quote + 1] == ',';
}