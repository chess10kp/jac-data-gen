"""Partial search of list of tuples with empty-string wildcards in findme."""
def tupleSearch(findme: tuple[str, ...], haystack: list[tuple[str, ...]]) -> list[tuple[str, ...]] {
    `match = [];
    for words in haystack {
        testmatch = [];
        for (i, j) in zip(findme, words) {
            testmatch.append(not i or i == j);
        }
        if all(testmatch) {
            `match.append(words);
        }
    }
    return `match;
}