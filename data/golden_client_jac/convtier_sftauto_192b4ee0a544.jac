def remove_duplicates(sentence: Any) -> object {
    words = sentence.split();
    cleaned_sentence = [];
    for word in words {
        if (word not in cleaned_sentence) {
            cleaned_sentence.append(word);
        }
    }
    return ' '.join(cleaned_sentence);
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
