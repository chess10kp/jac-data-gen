"""Extract all words from a list of strings."""
def ExtractWordsFromLines(lines: list[str]) -> set[str] {
    words = set();
    for line in lines {
        for word in line.split() {
            words.add(word);
        }
    }
    return words;
}