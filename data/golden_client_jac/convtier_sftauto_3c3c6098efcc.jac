def is_palindrome(sentence: Any) -> object {
    sentence = ''.join(
        e
        for e in sentence
        if e.isalpha()
    );
    sentence = sentence.lower();
    return (sentence == sentence[::-1]);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
