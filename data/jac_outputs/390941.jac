""" Get line and column (1-based) from character index """
def _get_line_col(code: str, idx: int) -> tuple[int, int] {
    line = len(code[:(idx + 1)].splitlines());
    col = idx - (code[:(idx + 1)].rfind('\n') + 1);
    return (line, col);
}