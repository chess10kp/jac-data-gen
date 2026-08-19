def is_palindrome(word: Any) -> object {
    word = ''.join(
        ch
        for ch in word
        if ch.isalnum()
    ).lower();
    return (word == word[::-1]);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
