"""Transform empty strings values of dict `row` to None."""
def _clean_dict(row: dict[str, str | None]) -> dict[str, str | None] {
    row_cleaned = {};
    for (key, val) in row.items() {
        row_cleaned[key] = None if val is None or val == "" else val;
    }
    return row_cleaned;
}