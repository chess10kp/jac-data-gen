def is_pangram(s: str) -> bool {
    letters: set = set([c for c in s.lower() if c.isalpha()]);
    return len(letters) == 26;
}

with entry {
    print(is_pangram("the quick brown fox jumps over the lazy dog"));
}
