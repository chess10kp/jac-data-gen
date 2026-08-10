"""Accept a literal character at the current buffer position."""
def accept_lit(char: str, buf: str, pos: int) -> tuple[str | None, int] {
    if pos >= len(buf) or buf[pos] != char {
        return (None, pos);
    }
    return (char, pos + 1);
}