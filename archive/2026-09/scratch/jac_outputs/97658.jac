"""Calculate row format."""
def calculate_row_format(columns: dict[str, int], keys: list[str] | None = None) -> str {
    row_format = '';
    effective_keys = list(columns.keys()) if keys is None else [key for key in keys if key in columns];
    for key in effective_keys {
        if len(row_format) > 0 {
            row_format += "|";
        }
        row_format += "%%(%s)-%ds" % (key, columns[key]);
    }
    return '|' + row_format + '|';
}