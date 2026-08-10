glob UINT64_MAX = "18446744073709551615";

"""Generate a query to retrieve data from database."""
def make_query(specific_table: str, offset: int | str | float | bool | None) -> str {
    query = 'select DISTINCT * from `{}`'.format(specific_table);
    if isinstance(offset, int) {
        query += " LIMIT {}, {};".format(str(offset), UINT64_MAX);
    }
    return query;
}