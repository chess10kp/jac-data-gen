"""Prepare the columns to be selected by the SELECT statement."""
def getSelectColumns(columns: str | list[str]) -> str {
    if columns == '*' {
        return columns as str;
    }
    return ', '.join(columns);
}