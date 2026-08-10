"""Count frequency of each word and return a word-to-count mapping."""
def count_frequency(word_list: list[str]) -> dict[str, int] {
    counts: dict[str, int] = {};
    for word in word_list {
        counts[word] = counts.get(word, 0) + 1;
    }
    return counts;
}