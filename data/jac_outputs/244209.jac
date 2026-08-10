"""Construct a string suitable for a spreadsheet."""
def _buildstr(
    D: list[list[str | int | float]] | list[str | int | float] | str | int | float,
    transpose: bool = False,
    replace: tuple[str, str] | None = None
) -> str {
    data = D;
    try {
        data[0];
    } except (TypeError, IndexError) {
        data = [data] as list[list[str | int | float]];
    }
    try {
        data[0][0];
    } except (TypeError, IndexError) {
        data = [data] as list[list[str | int | float]];
    }
    if transpose {
        data = zip(*data) as list[list[str | int | float]];
    }
    if not replace {
        rows = ['\t'.join([str(v) for v in row]) for row in data];
    } else {
        rows = ['\t'.join([str(v).replace(*replace) for v in row]) for row in data];
    }
    return '\n'.join(rows);
}