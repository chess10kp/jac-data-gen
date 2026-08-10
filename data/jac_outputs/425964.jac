"""Reads to the next divider line.

    Read lines are returned, 'lines' is reduced to everything remaining.
    """
def read_table(lines: list[str]) -> list[str] {
    table_lines = [];
    while len(lines) {
        popline = lines[0];
        lines = lines[1:];
        if popline[:6] == "======" {
            break;
        }
        table_lines += [popline];
    }
    return table_lines;
}