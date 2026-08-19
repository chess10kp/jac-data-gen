def is_uppercase_multiple_of_seven(char: Any) -> object {
    if (char.isupper() and ((ord(char) % 7) == 0)) {
        return True;
    } else {
        return False;
    }
}



with entry {
    print(is_uppercase_multiple_of_seven('hello'));
}
