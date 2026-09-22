"""Delete the comment from the parameter setting string."""
def del_comment(string: str) -> str {
    return string.split('#')[0].replace(' ', '');
}