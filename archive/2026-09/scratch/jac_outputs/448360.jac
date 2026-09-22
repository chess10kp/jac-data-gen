"""Return a list of table_names."""
def extract_tables_from_query(sql_query: str) -> list[str] {
    return [
        word
        for word in sql_query.split(" ")
        if len(word.split(".")) == 3
    ];
}