obj WordCounter {
    has counts: dict[str, int] = {};

    def add(word: str) -> None {
        self.counts[word] = self.counts.get(word, 0) + 1;
    }

    def get_count(word: str) -> int {
        return self.counts.get(word, 0);
    }
}

with entry {
    c = WordCounter();
    for w in ["a", "b", "a", "a"] { c.add(w); }
    print(c.get_count("a"));
    print(c.get_count("b"));
}
