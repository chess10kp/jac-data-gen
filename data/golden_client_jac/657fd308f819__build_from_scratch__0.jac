def vowel_count(s: str) -> int {
    count = 0;
    for c in s {
        if c in "aeiou" { count += 1; }
    }
    return count;
}
