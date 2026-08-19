def check_string(string: Any) -> object {
    if not string.isalpha() {
        return False;
    }
    if (
        not `any(char.isupper() for char in string)
        or not `any(char.islower() for char in string)
    ) {
        return False;
    }
    return True;
}



with entry {
    print(check_string('hello'));
    print(check_string('Racecar'));
}
