"""Returns the line and column of the given position in the string."""
def get_line_column(data: str, line: int, column: int, position: int) -> tuple[int, int] {
    data = data[:position];
    toks = data.splitlines();
    if not toks or data[-1] in "\n\r" {
        toks.append("");
    }
    if len(toks) > 1 {
        return ((line + len(toks)) - 1, 1 + len(toks[-1]));
    }
    return (line, column + position);
}