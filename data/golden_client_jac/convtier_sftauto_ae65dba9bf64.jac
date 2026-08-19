def is_valid_binary_number(number: Any) -> object {
    try {
        int(number, 2);
        return True;
    } except ValueError {
        return False;
    }
}



with entry {
    print(is_valid_binary_number('hello'));
}
