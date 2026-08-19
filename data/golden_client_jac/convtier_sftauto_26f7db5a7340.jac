def remove_punctuation(string: Any) -> object {
    punctuation_marks = [
        ",",
        ".",
        "!",
        "?",
        ";",
        ":",
        "'",
        "\"",
        "(",
        ")",
        "[",
        "]",
        "{",
        "}",
        "<",
        ">"
    ];
    lowercase_string = "";
    for char in string {
        if (char not in punctuation_marks) {
            lowercase_string += char.lower();
        }
    }
    return lowercase_string;
}



with entry {
    print(remove_punctuation('hello'));
    print(remove_punctuation('Racecar'));
    print(remove_punctuation('abcabc'));
}
