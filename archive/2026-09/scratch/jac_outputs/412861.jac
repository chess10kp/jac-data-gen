"""Trim off the extra columns."""
def orm_coerce_row(row: list[str | int | float | None], extra_columns: list[str], result_type: type) -> tuple[str | int | float | None, ...] {
    n = len(row) - len(extra_columns);
    return result_type(row[:n]);
}