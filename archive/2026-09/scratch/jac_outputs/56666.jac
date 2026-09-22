"""Heuristically finds schema entities included in a SQL query."""
def find_used_entities_in_string(query: str, columns: set[str], tables: set[str]) -> tuple[set[str], set[str]] {
    used_columns = set();
    used_tables = set();
    nopunct_query = query.replace('.', ' ').replace('(', ' ').replace(')', ' ');
    for token in nopunct_query.split(' ') {
        if token.lower() in columns {
            used_columns.add(token.lower());
        }
        if token.lower() in tables {
            used_tables.add(token.lower());
        }
    }
    return (used_columns, used_tables);
}