def char_frequency(s: str) -> dict[str, int] {
    freq: dict[str, int] = {};
    for ch in s {
        freq[ch] = freq.get(ch, 0) + 1;
    }
    return freq;
}

with entry {
    print(char_frequency("aab"));
}
