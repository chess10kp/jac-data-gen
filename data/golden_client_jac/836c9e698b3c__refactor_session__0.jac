def _matches(item: str, query: str) -> bool {
    q = query.lower().strip();
    return q in item.lower();
}

def _search_filter(contents: list, query: str) -> list {
    return [c for c in contents if _matches(c, query)];
}
