def count_words(s: str) -> int {
    return len(s.split());
}

with entry {
    print(count_words("one two three"));
}
