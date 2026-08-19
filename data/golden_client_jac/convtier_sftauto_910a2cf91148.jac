def is_palindrome(string: Any) -> object {
    return (string == string[::-1]);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('level'));
}
