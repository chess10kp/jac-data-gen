def remove_digits_special_chars(string: Any) -> object {
    new_string = "";
    for char in string {
        if char.islower() {
            new_string += char;
        }
    }
    return new_string;
}



with entry {
    print(remove_digits_special_chars('hello'));
    print(remove_digits_special_chars('Racecar'));
    print(remove_digits_special_chars('abcabc'));
}
