def longest_word(s: str) -> str {
    best = "";
    for word in s.split() {
        if len(word) > len(best) { best = word; }
    }
    return best;
}

with entry {
    print(longest_word("i ate a banana"));
}
