def convert_sentence_to_list(sentence: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u'];
    words = [];
    sentence_words = sentence.split();
    for word in sentence_words {
        if ((word[0].lower() not in vowels) and (len(word) <= 3)) {
            words.append(word);
        }
    }
    return sorted(words);
}



with entry {
    print(convert_sentence_to_list('hello'));
    print(convert_sentence_to_list('step on no pets'));
}
