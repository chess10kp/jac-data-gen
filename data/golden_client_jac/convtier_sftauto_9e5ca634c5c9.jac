def extract_words(list_of_strings: Any) -> object {
    extracted_words = [];
    for word in list_of_strings {
        if (word.lower().startswith('s') and word.lower().endswith('t')) {
            extracted_words.append(word);
        }
    }
    return extracted_words;
}



with entry {
    print(extract_words('hello'));
}
