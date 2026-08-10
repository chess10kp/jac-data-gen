"""Split a line into pieces and parse the strings."""
def split_line(line: str, parsers: list[Callable[[str], int | float | str]], sep: str = " ") -> list[int | float | str] | int | float | str {
    parts = [part for part in line.split(sep) if part];
    values = [parser(part) for (parser, part) in zip(parsers, parts)];
    return values if len(values) > 1 else values[0];
}