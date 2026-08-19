def vowel_count(s: str) -> int {
    count = 0;
    for c in s.lower() {
        if c in "aeiou" {
            count += 1;
        }
    }
    return count;
}

with entry {
    for x in ["Hello", "AEIOU", "xyz", "Programming"] {
        print(vowel_count(x));
    }
}
