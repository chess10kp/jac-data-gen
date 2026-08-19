def capitalize_strings(strings: Any) -> object {
    capitalized_strings = [];
    for string in strings {
        new_string = "";
        for (i, char) in enumerate(string) {
            if char.isalpha() {
                if (i == 0) {
                    new_string += char.upper();
                } else {
                    new_string += char.lower();
                }
            }
        }
        capitalized_strings.append(new_string);
    }
    return capitalized_strings;
}



with entry {
    print(capitalize_strings('hello'));
    print(capitalize_strings('Racecar'));
    print(capitalize_strings('abcabc'));
}
