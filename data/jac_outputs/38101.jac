"""Rename environment."""
def renameEnv(lines: list[str], newname: str) -> list[str] {
    for (i, line) in enumerate(lines) {
        if line.startswith('name: ') {
            lines[i] = 'name: ' + newname;
        }
    }
    return lines;
}