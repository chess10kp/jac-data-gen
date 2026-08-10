"""This takes a row from a resultset and returns a dict with the same structure."""
def row_to_dict(row: dict[str, str]) -> dict[str, str] {
    return {key: value for (key, value) in row.items()};
}