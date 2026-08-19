def longest_non_repeating_substring(s: Any) -> object {
    n = len(s);
    max_len = 0;
    start = 0;
    seen = {};
    for end in range(n) {
        if (s[end] in seen) {
            start = max(start, (seen[s[end]] + 1));
        }
        seen[s[end]] = end;
        max_len = max(max_len, ((end - start) + 1));
    }
    return max_len;
}



with entry {
    print(longest_non_repeating_substring('hello'));
    print(longest_non_repeating_substring('Racecar'));
    print(longest_non_repeating_substring('Hello, World!'));
}
