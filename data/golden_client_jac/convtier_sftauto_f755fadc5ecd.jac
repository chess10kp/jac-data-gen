def validate_string(string: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u'];
    if ((len(string) < 10) or (len(string) > 30)) {
        return False;
    }
    if `any((char.isdigit() or not char.isalnum()) for char in string) {
        return False;
    }
    if (string[0].lower() in vowels) {
        return False;
    }
    for i in range((len(string) - 3)) {
        substring = string[i:(i + 4)];
        if (string.count(substring) > 1) {
            return False;
        }
    }
    return True;
}



with entry {
    print(validate_string('hello'));
}
