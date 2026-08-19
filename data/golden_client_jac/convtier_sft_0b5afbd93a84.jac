def group_by_initial(words: list[str]) -> dict[str, list[str]] {
    return {
        c: [w for w in words if w[0] == c]
        for c in sorted({w[0] for w in words})
    };
}

with entry {
    print(group_by_initial(['ant', 'bee', 'ape']));
}
