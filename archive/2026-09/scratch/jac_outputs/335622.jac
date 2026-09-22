"""
    Builds an SQL style query string from a dictionary
        where keys are column titles and values are values
        that the query will test for.
"""
def build_SQL_query(query_words: dict[str, bool | str | int | float]) -> str {
    query_string = '';
    for (col_nm, col_val) in query_words.items() {
        if col_val not in [True, False] {
            col_val = f"'{col_val}'";
        }
        query_string += f"{col_nm}=={col_val}";
        if col_nm != list(query_words.keys())[-1] {
            query_string += " & ";
        }
    }
    return query_string;
}