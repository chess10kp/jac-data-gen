def is_palindrome(n: Any) -> object {
    return (str(n) == str(n)[::-1]);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('level'));
}
