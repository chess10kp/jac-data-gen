"""
    Sanitizes input for SQLite TEXT fields by converting to string and replacing
    each single quote (') with two single quotes ('')
    """
def strSQLite(string: int | float | str | bool) -> str {
    return str(string).replace("'", "''");
}