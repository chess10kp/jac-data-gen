def reverse_words(s: str) -> str {
    return " ".join(s.split()[::-1]);
}

with entry {
    for x in ["hello world foo", "one two three four", "single", "a b c"] {
        print(reverse_words(x));
    }
}
