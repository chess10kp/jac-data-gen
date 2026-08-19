def is_palindrome(string: Any) -> object {
    normalized_string = ''.join(
        c.lower()
        for c in string
        if c.isalnum()
    );
    return (normalized_string == normalized_string[::-1]);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
