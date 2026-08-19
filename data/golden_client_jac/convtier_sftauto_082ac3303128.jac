def is_palindrome(num: Any) -> object {
    num_str = str(num);
    if (num_str == num_str[::-1]) {
        return True;
    }
    return False;
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('level'));
}
