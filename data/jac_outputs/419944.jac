"""Reformat a query string to remove newlines and extra spaces."""
def _query_single_line[T](query: T) -> str {
    return " ".join(str(query).split());
}