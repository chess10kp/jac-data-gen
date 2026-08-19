def is_palindrome(word: Any) -> object {
    cleaned_word = ''.join(
        c.lower()
        for c in word
        if c.isalnum()
    );
    return (cleaned_word == cleaned_word[::-1]);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
