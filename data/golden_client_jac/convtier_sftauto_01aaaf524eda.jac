def convert_to_lowercase(string: Any) -> object {
    new_string = "";
    for char in string {
        if char.isalpha() {
            new_string += char.lower();
        } else {
            new_string += char;
        }
    }
    return new_string;
}



with entry {
    print(convert_to_lowercase('hello'));
    print(convert_to_lowercase('Racecar'));
    print(convert_to_lowercase('abcabc'));
}
