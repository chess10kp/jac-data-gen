def remove_spaces_and_punctuation(s: Any) -> object {
    result = "";
    for char in s {
        if char.isalnum() {
            result += char;
        }
    }
    return result;
}



with entry {
    print(remove_spaces_and_punctuation('hello'));
    print(remove_spaces_and_punctuation('Racecar'));
    print(remove_spaces_and_punctuation('abcabc'));
}
