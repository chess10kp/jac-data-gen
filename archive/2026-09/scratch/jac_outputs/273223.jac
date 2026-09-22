"""Remove white spaces, tabs, and new lines from a string."""
def rws(t: str) -> str {
    for c in ['\n', '\t', ' '] {
        t = t.replace(c, '');
    }
    return t;
}