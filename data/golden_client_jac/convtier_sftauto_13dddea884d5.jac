def is_palindrome(arr: Any) -> object {
    reversed_arr = arr[::-1];
    return (arr == reversed_arr);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('level'));
}
