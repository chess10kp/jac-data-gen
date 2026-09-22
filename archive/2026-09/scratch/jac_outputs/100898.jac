"""Transforms hierarchical column names to concatenated single-level columns."""
def flatten_columns(columns: list[list[str]]) -> list[str] {
    return ['_'.join(col).strip() for col in columns];
}