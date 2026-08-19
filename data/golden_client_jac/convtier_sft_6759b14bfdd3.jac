def reverse_words(s: str) -> str {
    return " ".join(list(reversed(s.split())));
}

with entry {
    print(reverse_words("one two three"));
}
