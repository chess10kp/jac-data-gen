"""Return a tuple of statements granting privileges on the database.
    :param database_name: Database name
    :type: str
    :return: a tuple of statements
    :rtype: tuple(str)
    """
def _database_privileges_sql_limited(database_name: Any) -> object {
    tmpl = 'grant create on database {db} to {usr}';
    return (tmpl.format(db=database_name, usr='loading_user'), );
}