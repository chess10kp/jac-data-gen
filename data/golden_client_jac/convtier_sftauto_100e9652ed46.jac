def longest_palindrome(s: Any) -> object {
    longest = "";
    for i in range(len(s)) {
        for j in range(i, len(s)) {
            substring = s[i:(j + 1)];
            if (is_palindrome(substring) and (len(substring) > len(longest))) {
                longest = substring;
            }
        }
    }
    return longest;
}



with entry {
    print(longest_palindrome([]));
}
