"""Clean page_path: collapse slashes and strip after sep."""
def clean_page_path(page_path: str, sep: str = '#') -> str {
    return page_path.replace('//', '/').rsplit(sep, 1)[0];
}