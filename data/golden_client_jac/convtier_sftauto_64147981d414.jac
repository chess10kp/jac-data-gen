def capitalize_string(s: Any) -> object {
    capitalized_string = "";
    for word in s.split() {
        capitalized_string += word[0].upper() + word[1:] + " ";
    }
    return capitalized_string.strip();
}



with entry {
    print(capitalize_string('hello'));
    print(capitalize_string('Racecar'));
    print(capitalize_string('abcabc'));
}
