"""Helper function for getting length of indent for line."""
def get_indent(line: str) -> int {
    for (idx, char) in enumerate(line) {
        if not char.isspace() {
            return idx;
        }
    }
    return len(line);
}