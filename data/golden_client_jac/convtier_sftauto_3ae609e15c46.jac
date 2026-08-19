def is_palindrome(word: Any) -> object {
    return (word == word[::-1]);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('level'));
}
