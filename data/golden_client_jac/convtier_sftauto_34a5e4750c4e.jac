def is_palindrome(string: Any) -> object {
    string = string.lower();
    string = ''.join(
        e
        for e in string
        if e.isalnum()
    );
    return ((string == string[::-1]) and (len(string) >= 3));
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
