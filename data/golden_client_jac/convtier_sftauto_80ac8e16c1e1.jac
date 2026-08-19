def capitalize_words(string: Any) -> object {
    words = string.split();
    capitalized_words = [word.capitalize() for word in words];
    capitalized_string = ' '.join(capitalized_words);
    return capitalized_string;
}



with entry {
    print(capitalize_words('hello'));
    print(capitalize_words('Racecar'));
    print(capitalize_words('abcabc'));
}
