def is_palindrome_list(string_list: Any) -> object {
    for string in string_list {
        if (string != string[::-1]) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_palindrome_list('hello'));
}
