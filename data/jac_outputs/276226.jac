"""Adds a line of space between the passed in lines."""
def _Spaced(lines: list[str]) -> list[str] {
    spaced_lines = [];
    for line in lines {
        if spaced_lines {
            spaced_lines.append(' ');
        }
        spaced_lines.append(line);
    }
    return spaced_lines;
}