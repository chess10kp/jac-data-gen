def is_palindrome(string: Any) -> object {
    clean_string = ''.join(
        char.lower()
        for char in string
        if char.isalpha()
    );
    return (clean_string == clean_string[::-1]);
}



with entry {
    print(is_palindrome('hello'));
    print(is_palindrome('Racecar'));
}
