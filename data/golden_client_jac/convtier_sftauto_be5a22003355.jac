def capitalize_words(string: Any) -> object {
    string = string.strip();
    words = string.split();
    capitalized_words = [(word[0].upper() + word[1:]) for word in words];
    capitalized_string = ' '.join(capitalized_words);
    return capitalized_string;
}



with entry {
    print(capitalize_words('hello'));
    print(capitalize_words('Racecar'));
    print(capitalize_words('abcabc'));
}
