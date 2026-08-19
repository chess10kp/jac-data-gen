def invert_tags(docs: dict[str, list[str]]) -> dict[str, list[str]] {
    tags: list[str] = sorted({t for ts in docs.values() for t in ts});
    return {t: sorted([d for (d, ts) in docs.items() if t in ts]) for t in tags};
}

with entry {
    print(invert_tags({'a.txt': ['ml', 'jac'], 'b.txt': ['jac']}));
}
