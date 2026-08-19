def is_palindrome(num: Any) -> object {
    return (str(num) == str(num)[::-1]);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('level'));
}
