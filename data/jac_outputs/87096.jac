"""Deletes all the spaces of a string."""
def delete_spaces(s: str) -> str {
    ''.join(i for i in s if i != ' ')
}