"""Return a string with consistent line endings."""
def normalize_line_endings(string: str, eol: str) -> str {
    string = string.replace("\r\n", "\n").replace("\r", "\n");
    if eol != "\n" {
        string = string.replace("\n", eol);
    }
    return string;
}