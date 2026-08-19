def is_palindrome(s: Any) -> object {
    s = ''.join(
        char.lower()
        for char in s
        if char.isalnum()
    );
    count = 0;
    for i in range(len(s)) {
        if (((i + 4) < len(s)) and (s[i:(i + 5)] == s[i:(i + 5)][::-1])) {
            count += 1;
            i += 4;
        }
    }
    return count;
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
