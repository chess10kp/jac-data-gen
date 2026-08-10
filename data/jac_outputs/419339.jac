"""Cleaned column name suitable for SQL."""
def sql_name(raw_name: str) -> str {
    sql_name = raw_name;
    for to_replace in ['"', ' ', '\\', '/', '(', ')', '.'] {
        sql_name = sql_name.replace(to_replace, '_');
    }
    return sql_name.strip();
}