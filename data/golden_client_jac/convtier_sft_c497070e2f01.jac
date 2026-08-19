def count_vowels(s: str) -> int {
    count = 0;
    for ch in s.lower() {
        if ch in "aeiou" { count += 1; }
    }
    return count;
}

with entry {
    print(count_vowels("Education"));
}
