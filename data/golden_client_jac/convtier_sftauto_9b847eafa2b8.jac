def reverse_sentence(sentence: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u'];
    words = sentence.split();
    reversed_sentence = [];
    for word in words {
        if ((len(word) <= 5) or (word[0].lower() in vowels)) {
            reversed_sentence.append(word);
        }
    }
    reversed_sentence.reverse();
    return ' '.join(reversed_sentence);
}



with entry {
    print(reverse_sentence('hello'));
    print(reverse_sentence('Racecar'));
    print(reverse_sentence('abcabc'));
}
