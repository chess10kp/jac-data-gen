def is_palindrome(sentence: Any) -> object {
    sentence = ''.join(
        ch.lower()
        for ch in sentence
        if ch.isalnum()
    );
    return (sentence == sentence[::-1]);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
