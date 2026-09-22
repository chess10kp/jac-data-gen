"""Support 'WHERE IN' SQL templates.  Replace the first occurence of the
    string '(?...?)' with some number of qmarks, e.g. '(?,?,?)'."""
def sql_replace_where_in(sql: str, q_count: int) -> str {
    qs = ','.join('?' * q_count);
    return sql.replace('?...?', qs);
}