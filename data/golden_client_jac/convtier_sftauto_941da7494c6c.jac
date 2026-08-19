def is_palindrome(num: Any) -> object {
    num_str = str(num);
    return (num_str == num_str[::-1]);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('level'));
}
