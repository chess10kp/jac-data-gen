def count_uppercase(s: str) -> int {
    count = 0;
    for c in s {
        if c.isupper() { count += 1; }
    }
    return count;
}

with entry {
    print(count_uppercase("HeLLo"));
}
