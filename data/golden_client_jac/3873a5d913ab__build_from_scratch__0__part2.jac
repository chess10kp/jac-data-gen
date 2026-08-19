def word_count(s: str) -> int {
    return len(s.split());
}

with entry {
    for x in ["hello world", "one", "a b c d e", "   spaced   out  "] {
        print(word_count(x));
    }
}
