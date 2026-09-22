"""Rerurns the command
    Arguments:
        db_name {string} -- [description]
    Returns:
        string -- [description]
    """
def show_database_like(db_name: str) -> str {
    return "SHOW DATABASES LIKE '" + db_name + "'";
}