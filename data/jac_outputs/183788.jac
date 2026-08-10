"""Helper returning query names indexed by (table, column) tuples."""
def _get_query_names_by_table_column_tuple(
    table_name: str, dwsupport_model: dict[str, object]
) -> dict[tuple[str, str], list[str]] {
    query_names_by_table_column_tuple: dict[tuple[str, str], list[str]] = dict();
    for query in dwsupport_model["queries"] as list[dict[str, object]] {
        if query["table"] == table_name {
            query_name = query["name"] as str;
            for (variable_table, columns) in (query["variables"] as dict[str, list[str]]).items() {
                for variable_column in columns {
                    key = (variable_table, variable_column);
                    try {
                        query_names_by_table_column_tuple[key].append(query_name);
                    } except KeyError {
                        query_names_by_table_column_tuple[key] = [query_name];
                    }
                }
            }
        }
    }
    return query_names_by_table_column_tuple;
}