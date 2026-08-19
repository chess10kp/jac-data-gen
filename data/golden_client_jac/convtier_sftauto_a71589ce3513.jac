def reverse_words(string: Any) -> object {
    reversed_string = "";
    current_word = "";
    for i in range((len(string) - 1), -1, -1) {
        if string[i].isalpha() {
            current_word += string[i];
        } else {
            reversed_string += current_word[::-1] + string[i];
            current_word = "";
        }
    }
    reversed_string += current_word[::-1];
    return reversed_string;
}



with entry {
    print(reverse_words('hello'));
    print(reverse_words('Racecar'));
    print(reverse_words('abcabc'));
}
