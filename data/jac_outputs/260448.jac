"""Splits into (head, tail), where head contains no '#' and is max length."""
def split_section(url: str) -> tuple[str, str] {
    if '#' in url {
        i = url.index('#');
        return (url[:i], url[i:]);
    }
    return (url, '');
}