def remove_words_with_numbers_and_capital_letters(list_of_strings: Any) -> object {
    filtered_words = [];
    for word in list_of_strings {
        if not `any(char.isdigit() for char in word) {
            if not word[0].isupper() {
                filtered_words.append(word);
            }
        }
    }
    return filtered_words;
}



with entry {
    print(remove_words_with_numbers_and_capital_letters('hello'));
    print(remove_words_with_numbers_and_capital_letters('Racecar'));
    print(remove_words_with_numbers_and_capital_letters('abcabc'));
}
