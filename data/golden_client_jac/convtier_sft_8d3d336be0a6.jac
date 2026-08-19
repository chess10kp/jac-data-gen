def search_filter(spec: dict) -> list {
    q = str(spec["query"]).lower().strip();
    return [c for c in spec["items"] if q in str(c).lower()];
}

with entry {
    print(search_filter({'items': ['Jac Lang', 'Python', 'Jaseci'], 'query': ' ja '}));
}
