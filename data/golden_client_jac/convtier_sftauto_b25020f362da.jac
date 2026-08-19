def is_palindrome(s: Any) -> object {
    clean_string = ''.join(
        ch.lower()
        for ch in s
        if ch.isalnum()
    );
    return (clean_string == clean_string[::-1]);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
