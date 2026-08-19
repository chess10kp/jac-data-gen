def capitalize_words(string: Any) -> object {
    return ' '.join(word.capitalize() for word in string.split());
}



with entry {
    print(capitalize_words('hello'));
    print(capitalize_words('Racecar'));
    print(capitalize_words('abcabc'));
}
