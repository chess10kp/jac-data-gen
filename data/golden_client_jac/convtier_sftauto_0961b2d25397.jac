def get_last_character(string: Any) -> object {
    if string {
        last_character = string[-1];
        uppercase_character = last_character.upper();
        return uppercase_character;
    } else {
        return "Input string is empty. Please provide a non-empty string.";
    }
}



with entry {
    print(get_last_character('hello'));
    print(get_last_character('Racecar'));
    print(get_last_character('abcabc'));
}
