def is_palindrome(string: Any) -> object {
    if (len(string) <= 1) {
        return True;
    }
    if (string[0] == string[-1]) {
        return is_palindrome(string[1:-1]);
    } else {
        return False;
    }
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome([2]));
}
