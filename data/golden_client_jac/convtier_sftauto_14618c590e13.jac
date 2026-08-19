def extract_unique_words(string: Any) -> object {
    unique_words = [];
    words = string.split();
    for word in words {
        if (word not in unique_words) {
            unique_words.append(word);
        }
    }
    return unique_words;
}



with entry {
    print(extract_unique_words('hello'));
    print(extract_unique_words('Racecar'));
    print(extract_unique_words('abcabc'));
}
