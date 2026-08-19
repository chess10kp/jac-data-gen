def is_palindrome(string: Any) -> object {
    left = 0;
    right = len(string) - 1;
    while (left < right) {
        if (string[left] != string[right]) {
            return False;
        }
        left += 1;
        right -= 1;
    }
    return True;
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('level'));
}
