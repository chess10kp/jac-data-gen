"""
    Returns a list of dictionaries.
    Each dictionary is the column name to its corresponding row value.
    """
def map_rows_to_cols(rows: Any, cols: Any) -> object {
    mapped_rows = [];
    for row in rows {
        mapped_rows.append({cols[i]: row[i] for i in range(len(cols))});
    }
    return mapped_rows;
}