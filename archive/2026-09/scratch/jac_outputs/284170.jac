"""Double brackets in regex of url_path for escape string formatting."""
def escape_curly_brackets(url_path: str) -> str {
    return url_path.replace('{', '{{').replace('}', '}}');
}