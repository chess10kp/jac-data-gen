"""Parse a query string into a dictionary."""
def extract_data_from_query(query: str) -> dict[str, str] {
    result = {};
    if query is '' {
        return result;
    }
    for q in query.split('&') {
        splitted = q.split('=');
        result[splitted[0]] = splitted[1];
    }
    return result;
}