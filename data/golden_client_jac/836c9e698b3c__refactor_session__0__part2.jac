"""_search_filter: per-item match predicate extracted; query normalized once."""

def _matches(item: str, q: str) -> bool {
    return q in item.lower();
}

def _search_filter(contents: list[str], query: str) -> list {
    q = query.lower().strip();
    return [c for c in contents if _matches(c, q)];
}

with entry {
    contents = ["Hello Jac", "Graph DB rocks", "jac is fun", "Python here"];
    for q in ["  JAC ", "graph", "xyz", ""] {
        print(str(_search_filter(contents, q)));
    }
}
