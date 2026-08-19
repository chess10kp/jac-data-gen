def is_palindrome(sentence: Any) -> object {
    sentence = ''.join(filter(str.isalnum, sentence.lower()));
    return (sentence == sentence[::-1]);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
