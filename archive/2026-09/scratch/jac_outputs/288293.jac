"""Return the where clause from the given query list."""
def get_where_clause(columns_to_query_lst: list[str]) -> str {
    equals_str = ["c." + row + " = t." + row for row in columns_to_query_lst];
    return "where " + " AND ".join(equals_str);
}