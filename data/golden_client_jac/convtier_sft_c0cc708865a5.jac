def first_non_repeating(s: str) -> str {
    counts: dict[str, int] = {};
    for ch in s { counts[ch] = counts.get(ch, 0) + 1; }
    for ch in s {
        if counts[ch] == 1 { return ch; }
    }
    return "";
}

with entry {
    print(first_non_repeating("aabbc"));
}
