"""Indent a multi-line string by given number of spaces."""
def indent(string: str, n: Any = 4) -> str {
    return "\n".join(((" " * n) + x) for x in str(string).split("\n"));
}