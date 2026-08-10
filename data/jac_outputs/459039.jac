"""Removes leading and trailing whitespaces in all but first line."""
def _strip_after_new_lines(s: str) -> str {
    lines = s.splitlines();
    if len(lines) > 1 {
        lines = [lines[0]] + [line.lstrip() for line in lines[1:]];
    }
    return '\n'.join(lines);
}