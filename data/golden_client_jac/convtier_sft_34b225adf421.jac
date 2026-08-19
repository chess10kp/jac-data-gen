def is_anagram(a: str, b: str) -> bool {
    return sorted(a) == sorted(b);
}

with entry {
    print(is_anagram("listen", "silent"));
    print(is_anagram("hello", "world"));
}
