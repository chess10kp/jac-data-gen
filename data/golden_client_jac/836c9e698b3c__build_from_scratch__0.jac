def _search_filter(contents: list, query: str) -> list {
    return [c for c in contents if query in c];
}
