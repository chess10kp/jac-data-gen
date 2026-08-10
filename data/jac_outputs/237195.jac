"""
    This function is dedicated to parse authors, it removes all the "and" but the last and and replace them with ", "
    """
def keep_last_and_only(authors_str: str) -> str {
    last_author = authors_str.split(" and ")[-1];
    without_and = authors_str.replace(" and ", ", ");
    str_ok = without_and.replace((", " + last_author), (" and " + last_author));
    return str_ok;
}