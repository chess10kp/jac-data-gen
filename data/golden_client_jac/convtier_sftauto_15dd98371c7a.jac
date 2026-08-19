def is_all_uppercase(string: Any) -> object {
    for char in string {
        if not ('A' <= char <= 'Z') {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_all_uppercase('hello'));
}
