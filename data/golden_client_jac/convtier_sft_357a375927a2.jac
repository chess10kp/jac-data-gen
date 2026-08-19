def pivot_counts(recs: list[dict]) -> dict[str, dict[str, int]] {
    cities: list[str] = sorted({r["city"] for r in recs});
    cats: list[str] = sorted({r["cat"] for r in recs});
    return {
        c: {k: len([1 for r in recs if r["city"] == c and r["cat"] == k]) for k in cats}
        for c in cities
    };
}

with entry {
    print(pivot_counts([{'city': 'nyc', 'cat': 'a'}, {'city': 'nyc', 'cat': 'b'}, {'city': 'la', 'cat': 'a'}]));
}
