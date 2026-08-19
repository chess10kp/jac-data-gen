def count_consonants(s: str) -> int {
    count = 0;
    for ch in s.lower() {
        if ch.isalpha() and ch not in "aeiou" { count += 1; }
    }
    return count;
}

with entry {
    print(count_consonants("hello"));
}
