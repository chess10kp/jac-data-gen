def sentence_reverse(sentence: Any) -> object {
    words = sentence.split();
    reversed_words = words[::-1];
    reversed_sentence = ' '.join(reversed_words);
    return reversed_sentence;
}



with entry {
    print(sentence_reverse('hello'));
    print(sentence_reverse('Racecar'));
    print(sentence_reverse('abcabc'));
}
