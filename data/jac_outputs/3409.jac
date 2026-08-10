"""Build INSERT column names, placeholders, and values from (option, value) pairs."""
def get_insert_components(options: list[tuple[str, str]]) -> tuple[str, str, tuple[str, ...]] {
    col_names = ','.join(opt[0] for opt in options);
    placeholders = ','.join(['?' for _ in options]);
    if len(col_names) > 0 {
        col_names = ',' + col_names;
    }
    if len(placeholders) > 0 {
        placeholders = ',' + placeholders;
    }
    values = tuple(opt[1] for opt in options);
    return (col_names, placeholders, values);
}