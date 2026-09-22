"""Cleans string of ' 's and 's."""
def clean_query_string(string: str) -> str {
    string.replace(' ', '%20');
    string.replace(',', '');
    return string;
}