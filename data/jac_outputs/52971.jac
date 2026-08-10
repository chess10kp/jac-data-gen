"""Add \ in front of * or _ so that Markdown doesn't interpret them."""
def protect_special_chars(lines: list[list[str]]) -> list[list[str]] {
    for (i, line) in enumerate(lines) {
        if line[0] in ('text', 'list', 'list-item') {
            protected_line = [];
            for c in line[1] {
                if c in '_*' {
                    protected_line.append('\\' + c);
                } else {
                    protected_line.append(c);
                }
            }
            lines[i][1] = ''.join(protected_line);
        }
    }
    return lines;
}