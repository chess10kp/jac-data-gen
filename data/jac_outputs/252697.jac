"""
    Build an insert request.

    Parameters
    ----------
    table : str
        Table where query will be directed.
    to_insert: iterable
        The list of columns where the values will be inserted.

    Returns
    -------
    str
        Built query string.

    """
def build_insert(table: Any, to_insert: Any) -> object {
    return (
        f'INSERT INTO \"{table}\" ('
        + ", ".join(f"{w}" for w in to_insert)
        + ") VALUES ("
        + ", ".join(f":{w}" for w in to_insert)
        + ")"
    );
}