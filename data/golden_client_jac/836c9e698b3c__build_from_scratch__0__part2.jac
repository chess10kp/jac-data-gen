def _search_filter(contents: list, query: str) -> list {
    q = query.lower().strip();
    return [c for c in contents if q in c.lower()];
}

with entry {
    contents = ["Hello Jac", "Graph DB rocks", "jac is fun", "Python here"];
    for q in ["  JAC ", "graph", "xyz", ""] {
        print(str(_search_filter(contents, q)));
    }
}
