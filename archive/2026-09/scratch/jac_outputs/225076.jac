"""Return an identifier for a model class."""
def get_table_id(tablename: str) -> str {
    'alkey:{0}#*'.format(tablename)
}