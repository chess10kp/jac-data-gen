def first_non_repeating_lowercase(string: Any) -> object {
    string = string.lower();
    for char in string {
        if (char.isalpha() and char.islower() and char.isalnum()) {
            if (string.count(char) == 1) {
                return char;
            }
        }
    }
    return None;
}



with entry {
    print(first_non_repeating_lowercase('hello'));
    print(first_non_repeating_lowercase('Racecar'));
    print(first_non_repeating_lowercase('level'));
}
