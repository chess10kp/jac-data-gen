def count_unique_substrings(s: Any) -> object {
    n = len(s);
    count = 0;
    for i in range(n) {
        for j in range(i, n) {
            substring = s[i:(j + 1)];
            if (len(`set(substring)) == len(substring)) {
                count += 1;
            }
        }
    }
    return count;
}



with entry {
    print(count_unique_substrings('hello'));
    print(count_unique_substrings('Racecar'));
    print(count_unique_substrings('abcabc'));
}
