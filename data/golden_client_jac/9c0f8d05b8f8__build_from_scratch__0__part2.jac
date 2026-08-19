def dedupe(items: list) -> list {
    seen = [];
    out = [];
    for x in items {
        if x not in seen {
            seen.append(x);
            out.append(x);
        }
    }
    return out;
}

with entry {
    for x in [[1, 2, 2, 3, 1], [5, 5, 5], [1, 2, 3], [4, 4, 3, 2, 3]] {
        print(dedupe(x));
    }
}
