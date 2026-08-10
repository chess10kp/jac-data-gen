"""Takes rows and length of headers to get columns based on 2D list index from rows"""
def get_columns(rows: Any, headers: Any) -> object {
    if headers {
        columns = [[x[j] for x in rows] for j in range(len(headers))];
        return columns;
    } else {
        raise Exception("Could not parse columns because of irregular headers");
    }
}