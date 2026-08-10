"""Strings joined by delimiter."""
def build_id(*elements: object, delimiter: str = '.') -> str {
    return delimiter.join(map(str, elements));
}