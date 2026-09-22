"""Delete newline characters at start and end of line."""
def clean_newline(line: str) -> tuple[bool, str] {
    return_line = line.strip('\r\n');
    if return_line != line {
        return (True, return_line);
    } else {
        return (False, line);
    }
}