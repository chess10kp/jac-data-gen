def reverse_sentence(sentence: Any) -> object {
    words = sentence.split(" ");
    reversed_words = [];
    for word in words {
        reversed_word = word[::-1];
        reversed_words.append(reversed_word);
    }
    reversed_sentence = " ".join(reversed_words);
    return reversed_sentence;
}



with entry {
    print(reverse_sentence('hello'));
    print(reverse_sentence('Racecar'));
    print(reverse_sentence('abcabc'));
}
