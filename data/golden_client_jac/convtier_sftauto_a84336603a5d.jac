def is_palindrome(n: Any) -> object {
    if (n < 10) {
        return True;
    }
    str_n = str(n);
    return ((str_n[0] == str_n[-1]) and is_palindrome(int(str_n[1:-1])));
}



with entry {
    print(is_palindrome(5));
    print(is_palindrome(10));
}
