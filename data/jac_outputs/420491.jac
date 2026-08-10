"""Returns the given line stripped of specific trailing characters (spaces, tabs, and newlines by default)."""
def rstrip_special(line: str, JUNK: str = "\n \t") -> str {
    i = len(line);
    while i > 0 and line[i - 1] in JUNK {
        i -= 1;
    }
    return line[:i];
}