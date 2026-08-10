""" Searches through the specified list of strings and returns the
    first line starting with the specified search string, or None if not found
    """
def lineStartingWith(string: str, lines: list[str]) -> str | None {
    for line in lines {
        if line.startswith(string) {
            return line;
        }
    } else {
        return None;
    }
}