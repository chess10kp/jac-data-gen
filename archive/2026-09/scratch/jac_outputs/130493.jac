""" takes a string of the form : part of query -- comment and returns only the former. """
def remove_sql_comment_from_string(string: str) -> str {
    string.strip().split('--')[0].strip()
}