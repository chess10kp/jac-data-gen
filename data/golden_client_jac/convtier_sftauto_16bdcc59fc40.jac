def reverse_sentence(sentence: Any) -> object {
    words = sentence.split();
    reversed_words = words[::-1];
    reversed_sentence = " ".join(reversed_words);
    return reversed_sentence;
}



with entry {
    print(reverse_sentence('hello'));
    print(reverse_sentence('Racecar'));
    print(reverse_sentence('abcabc'));
}
