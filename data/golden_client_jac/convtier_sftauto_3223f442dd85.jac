def is_palindrome(num: Any) -> object {
    num = str(`abs(num));
    return (num == num[::-1]);
}



with entry {
    print(is_palindrome(5));
    print(is_palindrome(10));
}
