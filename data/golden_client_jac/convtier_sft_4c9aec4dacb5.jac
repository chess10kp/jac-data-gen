def count_unique_consonants(s: str) -> int {
    consonants: set = set();
    for char in s.lower() {
        if char.isalpha() and char not in "aeiou" { consonants.add(char); }
    }
    return len(consonants);
}

with entry {
    print(count_unique_consonants("hello"));
}
