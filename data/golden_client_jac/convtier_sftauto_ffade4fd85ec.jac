def count_distinct_substrings(s: Any) -> object {
    n = len(s);
    substrings = `set();
    for i in range(n) {
        for j in range(i, n) {
            substr = s[i:(j + 1)];
            substrings.add(substr);
        }
    }
    return len(substrings);
}



with entry {
    print(count_distinct_substrings('hello'));
    print(count_distinct_substrings('Racecar'));
    print(count_distinct_substrings('abcabc'));
}
